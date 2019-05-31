# Slack

The slack notification sends to [Slack](https://www.slack.com/) using [chat.postMessage](https://api.slack.com/methods/chat.postMessage).

## Configuration

### Add API on Slack

Create a [new Slack App](https://api.slack.com/apps).

Under "Add features and functionality," choose "Permissions." Add the `channels:read` and `chat:write:bot` permissions. Save changes.

Back under "Basic Information," choose "Install you app to your workspace."

In "Basic Information," again navigate to "Add features and functionality" and "Permissions." After your app is installed on you workspace in the previous step, you will have an OAuth Access Token, starting with `xoxp-`. Copy that value.

### Setup in Errbit

On the App Edit Page, click to highlight the slack integration.
Input the "Slack OAuth Access Token" from setup.

Slack channels are comma separated and can either be environment-named or unnamed channels:

* Environment-named channels take the form of `environment:#slack-channel` (e.g. `staging:#errbit`)
* Unnamed channels are just the name of the channel (e.g. `#general`)

The first unnamed channel is the default channel. Problems from environments not matching named environments will be sent to the default channel. If no default channel is specified and a problem does not match a named environment, no notification will be sent.

#### Examples

If slack channels are set to `production:#general, #errbit`, then:

* A problem from `production` will be sent to the #general Slack channel
* A problem from `staging` (or anywhere else) will be sent to the #errbit channel

If slack channels are set to `production:#general`, then:

* A problem from `production` will be sent to the #general Slack channel
* A problem from `staging` (or anywhere else) will also be sent to the #general channel

If slack channels are set to `#general`, then

* All problems are sent to the #general channel
