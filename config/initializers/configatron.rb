pit = Pit.get(
  'youroom.twitter_fetcher',
  :require => {
    'youroom.consumer.key' => '',
    'youroom.consumer.secret' => '',
    'youroom.access_token.key' => '',
    'youroom.access_token.secret' => '',
    'twitter.consumer.key' => '',
    'twitter.consumer.secret' => ''
  })
configatron.youroom.consumer.key = pit['youroom.consumer.key']
configatron.youroom.consumer.secret = pit['youroom.consumer.secret']
# post by below user to youroom
configatron.youroom.access_token.key = pit['youroom.access_token.key']
configatron.youroom.access_token.secret = pit['youroom.access_token.secret']

configatron.twitter.consumer.key = pit['twitter.consumer.key']
configatron.twitter.consumer.secret = pit['twitter.consumer.secret']
