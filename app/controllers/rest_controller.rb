require 'json'
require 'rubygems'
require 'oauth'
require 'oauth/consumer'
require 'etc'

class RestController < ApplicationController

  BASE_URL = 'http://localhost:45100/remote' 
  SECRET_FILE = 'restaccess.txt'

  #------------------ handlers ------------------ 

  def hello
    send_request build_url('/hello')
  end

  #def library
    #send_request build_url('/library')
  #end

  def files
    send_request build_url('/library/files')
  end

  def search
    send_request build_url('/search')
  end

  def search_add
    send_post build_url('/search')
  end

  def rescue_action(exception)
    case exception 
    when ::ActionController::RoutingError,
      ::ActionController::UnknownAction then
      render_page('Unknown route or action','')
    else super end
  end

  #------------------- helpers -_-----------------

  def send_request(path)
    uri = URI.parse(BASE_URL+path)
    getreq = Net::HTTP::Get.new(uri.path)
    sign_request!(getreq)
    reqstr,respstr = start_request(getreq,uri)
    render_page(reqstr,respstr)
  end

  def send_post(path)
    uri = URI.parse(BASE_URL+path)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data( {'q'=>'myquery'}) #params)
    sign_request!(request)
    reqstr,respstr = start_request(request,uri)
    render_page(reqstr,respstr)
  end

#http = Net::HTTP.new(uri.host, uri.port)
#request = Net::HTTP::Post.new(uri.request_uri)
#request.set_form_data({"q" => "My query", "per_page" => "50"})
#response = http.request(request)

  def start_request(req,uri) 
    begin   
      reqstr = prep(req,uri)
      respstr = Net::HTTP::start(uri.host,uri.port) { |http|
          resp = http.request(req); prep(resp) }
    rescue Exception => e
      respstr = e.to_s end   
    return reqstr,respstr
  end

  def render_page(reqPane,respPane)
    render(:update) { |page|
      page.update(reqPane,respPane)}
  end

  def prep(httpobj,uri=nil)
    buf = !uri.nil? ? (complete_request_uri+'<br>'+uri.to_s+'<br>') : ''
    buf << httpobj.inspect.delete('#<>') 
    httpobj.each_header do |k,v|
        buf << "#{k}=#{v}" end 
    buf << '<br>' << (httpobj.body||'') 
  end
 
  def build_url(url)
    guid = params[:guid]
    url << '/'+guid unless guid.nil? or guid.empty?
    return url
  end

  #-------------------- OAuth-------------------- 

  def sign_request!(req)
    begin
      secret = IO.read(secret_path)
      OAuth::Consumer.new('restdemo',secret, {
         :site=>BASE_URL }).sign!(req)
    rescue Exception => e
      raise Exception, 'unable to sign request!: ' + e.to_s
    end
  end

  def secret_path
    File.expand_path( case
      when PLATFORM.include?('mswin')
        '~/Application Data/LimeWire'
      when PLATFORM.include?('linux')
        '~/.limewire'
      when PLATFORM.include?('darwin')
        '~/Library/Preferences/LimeWire'
      else raise 'Unknown Platform...'
    end)+'/'+SECRET_FILE
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
