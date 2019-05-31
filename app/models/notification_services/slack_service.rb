class NotificationServices::SlackService < NotificationService
  CHANNEL_NAME_REGEXP = /^[#:a-z\d_, -]+$/
  LABEL = "slack"
  FIELDS = [
    [:api_token, {
      placeholder: 'xoxp-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
      label:       'Slack OAuth Access Token'
    }],
    [:room_id, {
      placeholder: 'production:#general, #errbit',
      label:       'Notification channel(s)',
      hint:        'Label per-environment channels (e.g. production:#general will send production notifications to #general). All other notifications are sent to unlabelled channel (e.g. #errbit).'
    }]
  ]
  API_URL = 'https://slack.com/api/chat.postMessage'

  def check_params
    if api_token.blank?
      errors.add :api_token, "You must specify your Slack token"
    end
    if room_id.blank?
      errors.add :room_id, "You must specify your Slack room(s)."
    elsif !CHANNEL_NAME_REGEXP.match(room_id)
      errors.add :room_id, "Slack channel names must be lowercase, with no special characters or periods."
    end
  end

  def message_for_slack(problem)
    "[#{problem.app.name}][#{problem.environment}][#{problem.where}]: #{problem.error_class} #{problem.url}"
  end

  def post_payload(problem)
    {
      username:    "Errbit",
      icon_url:    "https://raw.githubusercontent.com/errbit/errbit/master/docs/notifications/slack/errbit.png",
      channel:     channel_for(problem.environment),
      attachments: [
        {
          fallback:   message_for_slack(problem),
          title:      problem.message.to_s.truncate(100),
          title_link: problem.url,
          text:       problem.where,
          color:      "#D00000",
          mrkdwn_in:  ["fields"],
          fields:     post_payload_fields(problem)
        }
      ]
    }
  end

  def create_notification(problem)
    return unless channel_for(problem.environment)

    HTTParty.post(
      API_URL,
      body:    post_payload(problem).to_json,
      headers: {
        'Content-Type' => 'application/json; charset=utf-8',
        'Authorization' => "Bearer #{api_token}"
      }
    )
  end

  def configured?
    api_token.present?
  end

  def channel_for(environment)
    list = room_id.split(/\s*,\s*/)
    default = list.reject { |c| c.match(':') }.first
    lookup = list
             .select { |c| c.match(':') }
             .map { |c| c.split(/\s*:\s*/) }
             .to_h
    lookup.fetch(environment, default)
  end

private

  def post_payload_fields(problem)
    [
      { title: "Application", value: problem.app.name, short: true },
      { title: "Environment", value: problem.environment, short: true },
      { title: "Times Occurred", value: problem.notices_count.try(:to_s),
        short: true },
      { title: "First Noticed",
        value: problem.first_notice_at.try(:localtime).try(:to_s, :db),
        short: true },
      { title: "Backtrace", value: backtrace_lines(problem), short: false }
    ]
  end

  def backtrace_line(line)
    path = line.decorated_path.gsub(%r{</?strong>}, '')
    "#{path}#{line.file_name}:#{line.number} → #{line.method}\n"
  end

  def backtrace_lines(problem)
    notice = NoticeDecorator.new problem.notices.last
    return unless notice
    backtrace = notice.backtrace
    return unless backtrace

    output = ''
    backtrace.lines[0..4].each { |line| output << backtrace_line(line) }
    "```#{output}```"
  end
end
