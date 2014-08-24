require 'rubygems'
require 'sinatra'
require 'twilio-ruby'
require 'pry'


get '/' do

  contactsList = {
    '+13057930809' => 'Stephanie',
    '+14157257171' => 'Dom'
  }

  contactsName = contactsList[params['From']] || ''

  helloMsg = "Hello #{contactsName}."
  getRecord(helloMsg)

end

get '/playback' do

  Twilio::TwiML::Response.new do |response|
    response.Play params['RecordingUrl']
    response.Gather :numDigits => '1', :timeout => 15, :action => "/playback/handle-recording/#{params['RecordingSid']}", :method => 'get' do |gather|
      gather.Say 'To continue, press 1'
      gather.Say 'To delete, press 2'
      gather.Say 'Then, press pound'
    end

  end.text
end

get '/playback/handle-recording/:recordingSID' do
  if params['Digits'] == '2'
    puts "IF STATEMENT"
    delete(params['recordingSID'])
    deletedMsg = "Audio deleted."
    getRecord(deletedMsg)

  elsif params['Digits'] != '2'
    puts "ELSE STATEMENT"
    getFeed()

  end

end

get'/feed' do

  Twilio::TwiML::Response.new do |response|

    response.Say 'Here are the recordings from today.'
    latestTenRecordings = client().account.recordings.list()[1..3]

    latestTenRecordings.each do |recording|

      response.Play recording.mp3()

    end

    response.Say 'Goodbye.'

  end.text

end


helpers do

  def client
    account_sid = ENV['ACCOUNT_SID']
    auth_token = ENV['AUTH_TOKEN']
    client = Twilio::REST::Client.new account_sid, auth_token
  end

  def delete(recording)
    recording = client().account.recordings.get(recording)
    recording.delete
  end

  def getFeed()
    redirect '/feed'
  end

  def getRecord(appendMsg)
    Twilio::TwiML::Response.new do |response|
      if appendMsg
        response.Say appendMsg
      end
      response.Say "Record your message."
      response.Record :maxLength => '5', :trim => "trim-silence", :playBeep => "true", :action => '/playback', :method => 'get'
    end.text
  end


end
