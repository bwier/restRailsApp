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
    send_request '/hello'
  end

  #def library
    #send_request build_url('/library')
  #end

  def files
    send_request '/library/files'
  end

  def search
    guid = guid(params[:guid])
    send_request('/search',guid)
  end

  def search_add
    send_post('/search',query('q')) 
  end
  
  def rescue_action(exception)
    case exception
    when ::ActionController::RoutingError,
        ::ActionController::UnknownAction then
      render_page(exception.inspect)
    else super end
  end

  #------------------- helpers -_-----------------

  def send_request(path,subpath=nil)
    begin
      uri = uri(path,subpath)
      getreq = Net::HTTP::Get.new(uri.path)
      sign_request!(getreq)
      start_request(getreq,uri)
    rescue Exception => e
      render_exception(getreq,e.to_s,uri)
    end
  end

  def send_post(path,query)
    begin 
      uri = uri(path,nil,query)
      postreq = Net::HTTP::Post.new(uri.request_uri)
      postreq.set_form_data(uri.query) 
      postreq['content-type'] = 'UTF-8'
      sign_request!(postreq)
      start_request(postreq,uri)
    rescue Exception => e
      render_exception(postreq,e.to_s,uri)
     end
  end

  def start_request(req,uri) 
    resp = Net::HTTP::start(uri.host,uri.port) { |http|
      http.request(req); }
    render_page(req,resp,uri)
  end

  def render_exception(request,exception,uri)
    reqstr = prep(request,uri)
    render(:update) { |page|
      page.update(reqstr,exception) }
  end

  def render_page(request,response,uri)
    reqstr = prep(request,uri)
    respstr = prep(response)
    render(:update) { |page|
      page.update(reqstr,respstr) }
  end

  def prep(httpobj,uri=nil)
    buf = !uri.nil? ? uri.normalize.to_s + '<br>' : '' 
    buf <<  httpobj.inspect.delete('#<>')
    httpobj.each_header do |k,v|
        buf << "#{k}=#{v} " end 
    buf << '<br>' << (httpobj.body||'') 
  end
 
  def uri(path,subpath=nil,query=nil)
    path << '/'+subpath unless !set?(subpath)
    path << '?'+query unless !set?(query)
    uri = URI.parse(BASE_URL+path)
  end

  def query(key,hash=params)
    val = hash[key] 
    query = set?(val) ? key+'='+val : ''
    query.gsub(' ','+') 
  end

  def guid(guidstr)
    len = guidstr.length #if not valid guid, return empty str
    return (len.eql?(32) ? guidstr : '') 
  end

  def set?(obj)
    !obj.nil? && !obj.empty?
  end

  #-------------------- OAuth-------------------- 

  def sign_request!(req)
    begin
      secret = IO.read(secret_path)
      OAuth::Consumer.new('restdemo',secret, {
         :site=>BASE_URL}).sign!(req)
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
