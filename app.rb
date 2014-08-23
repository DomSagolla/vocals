require 'rubygems'
require 'sinatra'
require 'twilio-ruby'


get '/' do

  contactsList = {
    '+13057930809' => 'Stephanie',
    '+14157257171' => 'Dom'
  }

  contactsName = contactsList[params['From']] || ''

  Twilio::TwiML::Response.new do |response|
    response.Say "Hello #{contactsName}. Record your message."
    response.Record :maxLength => '5', :trim => "trim-silence", :playBeep => "true", :action => '/recording', :method => 'get'

  end.text

end


get '/recording' do
  account_sid = ENV['ACCOUNT_SID']
  auth_token = ENV['AUTH_TOKEN']
  @client = Twilio::REST::Client.new account_sid, auth_token

  Twilio::TwiML::Response.new do |response|
    response.Play params['RecordingUrl']
    response.Say 'Here are the recordings from today.'
    latestTenRecordings = @client.account.recordings.list()[1..9]

    latestTenRecordings.each do |recording|
      
      response.Play recording.mp3()

    end

    response.Say 'Goodbye.'

  end.text
end
