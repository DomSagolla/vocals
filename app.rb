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
      gather.Say 'To continue, press 1', :voice => 'woman'
      gather.Say 'To delete, press 2', :voice => 'woman'
      gather.Say 'Then, press pound', :voice => 'woman'
    end

  end.text
end

get '/playback/handle-recording/:recordingSID' do
  if params['Digits'] == '2'
    delete(params['recordingSID'])

    deletedMsg = "Audio deleted."
    getRecord(deletedMsg)

  elsif params['Digits'] != '2'
    getFeed()

  end

end

get'/feed' do

  Twilio::TwiML::Response.new do |response|

    response.Say 'Here is your audio feed', :voice => 'woman'
    latestTenRecordings = client().account.recordings.list()[1..10]

    latestTenRecordings.each do |recording|

      response.Pause :length => '0.5'
      response.Play recording.mp3()
      response.Play '/pop'

    end
    response.Play '/end'
    response.Say 'Goodbye.', :voice => 'woman'

  end.text

end

get '/beep' do
  redirect '/beep.mp3'
end

get '/pop' do
  redirect '/pop.mp3'
end

get '/end' do
  redirect '/end.wav'
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
        response.Say appendMsg, :voice => 'woman'
        response.Pause :length => '1'
      end
      response.Say "Record your message.", :voice => 'woman'
      response.Play '/beep'
      response.Record :maxLength => '5', :trim => "trim-silence", :playBeep => "false", :action => '/feed', :method => 'get'
    end.text
  end


end
