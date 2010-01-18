pit = Pit.get(
  'youroom.twitter_fetcher',
  :require => {
    'consumer.key' => '',
    'consumer.secret' => '',
    'access_token.key' => '',
    'access_token.secret' => ''
  })
configatron.consumer.key = pit['consumer.key']
configatron.consumer.secret = pit['consumer.secret']
configatron.access_token.key = pit['access_token.key']
configatron.access_token.secret = pit['access_token.secret']
