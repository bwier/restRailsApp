require 'json'
require 'rubygems'
require 'oauth'
require 'oauth/consumer'
require 'etc'

class RestController < ApplicationController

  BASE_URL = 'http://localhost:45100/remote' 
  SECRET_FILE = 'restaccess.txt'

  #------------------ handlers ------------------ 

  def hello_action
    send_request '/hello'
  end

  def library_action
    send_request '/library' 
  end

  def files_action
    send_request '/library/files'
  end

  def search_action
    send_request '/search'
  end

#  def add_action
#      post_request LIBRARY_URL,'add'
#   end

  #------------------- helpers -_-----------------

  def send_request(path)
    req,resp = start_request(path)
    render(:update) { |page| 
      page.update(req,resp)}
  end

#  def post_form(path,action)
#    uri = URI.parse(ROOT+path)
#    resp = Net::HTTP.post_form(uri,params)
#    render :text => render_output(uri,resp)
#  end

  def start_request(path) 
    begin   
      uri = URI.parse(BASE_URL+path)
      req = Net::HTTP::Get.new(uri.path)
      resp = Net::HTTP::start(uri.host,uri.port) { |http|
                sign_request!(req); http.request(req) }
    rescue Exception => e
      return prep(req),e.to_s    
    end
    return prep(req),prep(resp)
  end

  def prep(httpobj,showurl=true)
buf = showurl ? complete_request_uri+'<br>' : ''
buf << httpobj.inspect.delete('#<>') 
      httpobj.each_header do |k,v|
        buf << "#{k}=#{v}" end 
      buf << '<p>' << (httpobj.body||'') 
  end

  #-------------------- OAuth-------------------- 

  def sign_request!(req)
    begin
      secret = IO.read(secret_file)
      OAuth::Consumer.new('restdemo',secret, {
         :site=>BASE_URL }).sign!(req)
    rescue 
      raise Exception, 'unable to sign request!'
    end
  end

  def secret_file
    (case when PLATFORM.include?('mswin')
      '~/Application Data/LimeWire'  
    when PLATFORM.include?('linux')
      '~/.limewire'
    when PLATFORM.include?('darwin4') 
      '~/Library/Preferences/LimeWire'
    else 'Unknown Platform...' end)+'/'+SECRET_FILE
  end

end

# DO NOT DELETE THIS!
#  def post_request(path,action)
#    params['action'] = action
#    req.set_form_data({:id=>'blah', :action => action })
#  end
#  def fetch_json_response(response,key='results')
#    jarr = JSON.parse(response)[key] 
    #jarr.each { |h| h['uri'] = CGI.unescape(h['uri']) } #decode
#    render :text => jarr.inspect 
#  end
