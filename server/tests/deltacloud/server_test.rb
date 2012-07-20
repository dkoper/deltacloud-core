require 'minitest/autorun'
require_relative 'common.rb'

describe Deltacloud::API do

  before do
    def app; Deltacloud::API; end
  end

  it 'has the config set property' do
    Deltacloud::API.config.must_be_kind_of Deltacloud::Server
    Deltacloud::API.config.root_url.must_equal Deltacloud[:deltacloud].root_url
  end

  it 'must provide the root_url entrypoint' do
    get Deltacloud::API.config.root_url
    status.must_equal 200
    xml.root.name.must_equal 'api'
  end

  it 'must advertise current API version in response headers' do
    get Deltacloud::API.config.root_url
    headers['Server'].must_match /Apache-Deltacloud\/(\d+).(\d+).(\d+)/
    xml.root.name.must_equal 'api'
  end

  it 'must advertise current API driver in response headers' do
    get Deltacloud::API.config.root_url
    headers['X-Deltacloud-Driver'].must_equal ENV['API_DRIVER']
    xml.root.name.must_equal 'api'
  end

  it 'must support matrix parameters for changing API driver' do
    get Deltacloud::API.config.root_url + ';driver=ec2'
    headers['X-Deltacloud-Driver'].must_equal 'ec2'
    xml.root.name.must_equal 'api'
  end

  it 'must support matrix parameters for changing API provider' do
    get Deltacloud::API.config.root_url + ';provider=someprovider'
    headers['X-Deltacloud-Provider'].must_equal 'someprovider'
    xml.root.name.must_equal 'api'
  end

  it 'must support matrix parameters for changing both API provider and driver' do
    get Deltacloud::API.config.root_url + ';provider=someprovider;driver=ec2'
    headers['X-Deltacloud-Provider'].must_equal 'someprovider'
    headers['X-Deltacloud-Driver'].must_equal 'ec2'
    xml.root.name.must_equal 'api'
  end

  it 'must change driver back to default when no matrix param set' do
    get Deltacloud::API.config.root_url + ';driver=ec2'
    headers['X-Deltacloud-Driver'].must_equal 'ec2'
    get Deltacloud::API.config.root_url
    headers['X-Deltacloud-Driver'].must_equal ENV['API_DRIVER']
    xml.root.name.must_equal 'api'
  end

  it 'must change provider back to default when no matrix param set' do
    get Deltacloud::API.config.root_url + ';provider=someprovider'
    headers['X-Deltacloud-Provider'].must_equal 'someprovider'
    get Deltacloud::API.config.root_url
    headers['X-Deltacloud-Provider'].must_be_nil
    xml.root.name.must_equal 'api'
  end

  it 'must support matrix params when they are part of URL' do
    get Deltacloud::API.config.root_url + ';driver=ec2/hardware_profiles'
    headers['X-Deltacloud-Driver'].must_equal 'ec2'
    status.must_equal 200
    xml.root.name.must_equal 'hardware_profiles'
  end

  it 'must switch driver using X-Deltacloud-Driver HTTP header in request' do
    header 'X-Deltacloud-Driver', 'ec2'
    get Deltacloud::API.config.root_url
    headers['X-Deltacloud-Driver'].must_equal 'ec2'
    header 'X-Deltacloud-Driver', 'mock'
    get Deltacloud::API.config.root_url
    headers['X-Deltacloud-Driver'].must_equal 'mock'
  end

  it 'must switch provider using X-Deltacloud-Provider HTTP header in request' do
    header 'X-Deltacloud-Provider', 'someprovider'
    get Deltacloud::API.config.root_url
    headers['X-Deltacloud-Provider'].must_equal 'someprovider'
    header 'X-Deltacloud-Provider', nil
    get Deltacloud::API.config.root_url
    headers['X-Deltacloud-Provider'].must_be_nil
  end

  it 'must support media type negotiation for JSON format' do
    header 'Accept', 'application/json'
    get Deltacloud::API.config.root_url
    status.must_equal 200
    headers['Content-Type'].must_equal 'application/json'
    JSON::parse(response_body).must_be_kind_of Hash
    JSON::parse(response_body)['api'].must_be_kind_of Hash
  end

  it 'must support media type negotiation for HTML format' do
    header 'Accept', 'text/html'
    get Deltacloud::API.config.root_url
    status.must_equal 200
    headers['Content-Type'].must_equal 'text/html'
    response_body.must_match /^<\!DOCTYPE html>/
  end

  it 'must support media type negotiation for XML format' do
    header 'Accept', 'application/xml'
    get Deltacloud::API.config.root_url
    status.must_equal 200
    headers['Content-Type'].must_equal 'application/xml'
    xml.root.name.must_equal 'api'
  end

  it 'must return proper error when unknown media type requested' do
    header 'Accept', 'application/unknown'
    get Deltacloud::API.config.root_url
    status.must_equal 406
  end

end
