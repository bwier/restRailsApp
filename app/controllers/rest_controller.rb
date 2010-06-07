require 'json'
require 'rubygems'
require 'oauth'
require 'oauth/consumer'
require 'etc'

class RestController < ApplicationController

  BASE_URL = 'http://localhost:45100/remote' 
  SECRET_FILE = 'restaccess.txt'

  # REST subpaths  
  LIB_URL   = '/library'
  FILE_URL  = '/files'
  SRCH_URL  = '/search'
  DWNLD_URL = '/download'
  HELLO_URL = '/hello'

  #------------------ handlers ------------------ 

  def hello
    send_request HELLO_URL
  end

  def files
    send_request LIB_URL+FILE_URL
  end

  def downloads
    send_request DWNLD_URL
  end

  # authentication not working 
  # for REST API download POSTs
  #def download_start
    #send_post(DWNLD_URL,query('magnet'))
  #end

  def search_all
    guid = guid(params[:guid])
    filepath = nil?(guid) ? '/'+guid+FILE_URL : '' 
    send_request(SRCH_URL+filepath)
  end

  def search_add
    send_post(SRCH_URL,query('q')) 
  end

  def search_delete
    guid = guid(params[:guid])
    send_delete(SRCH_URL+'/'+guid)
  end

  def rescue_action(exception)
    render_exception(exception.inspect)
  end

  #--------------- request helpers ----------------

  def send_request(path)
    begin
      uri = uri(path)
      getreq = Net::HTTP::Get.new(uri.path)
      resp = start_request(getreq,uri)
      render_page(getreq,resp,uri)
    rescue Exception => e
      render_exception(e.to_s,getreq,uri)
    end
  end

  def send_delete(path)
    begin 
      uri = uri(path)
      delreq = Net::HTTP::Delete.new(uri.request_uri)
      resp = start_request(delreq,uri)
      render_page(delreq,resp,uri)
    rescue Exception => e
      render_exception(e.to_s,delreq,uri)
     end
  end

  def send_post(path,query)
    begin
      raise Exception,'you must type a query!' unless nil?(query)
      uri = uri(path,query)
      postreq = post(uri)
      resp = start_request(postreq,uri)
      render_page(postreq,resp,uri)
    rescue Exception => e
      render_exception(e.to_s,postreq,uri)
    end
  end

  def start_request(req,uri) 
    sign_request!(req)
    resp = Net::HTTP::start(uri.host,uri.port) { |http|
      http.request(req); }
  end

  #--------------- rendering ------------------ 
  
  def render_exception(exception,request=nil,uri=nil)
    parsedEx = exception
    reqstr = !request.nil? ? pretty_prep(request,uri) : ''
    render(:update) { |page|
      page.update(reqstr,parsedEx) }
  end

  def render_page(request,response,uri)
    reqstr = pretty_prep(request,uri)
    respstr = pretty_prep(response)
    render(:update) { |page|
      page.update(reqstr,respstr) }
  end

  def pretty_prep(httpobj,uri=nil)
    buf = !uri.nil? ? uri.normalize.to_s + '<br>' : '' 
    buf <<  httpobj.inspect.delete('#<>')
    httpobj.each_header do |k,v|
        buf << "#{k}=#{v} " end 
    body = httpobj.body||''
    buf << '<br>' << body.gsub('},','},<br>')
  end

  #--------------- http objects -------------- 
 
  def post(uri)
    req = Net::HTTP::Post.new(uri.request_uri)
    req.set_form_data(uri.query)
    req['content-type'] = 'UTF-8'
    return req
  end

  def uri(path,query=nil)
    path << '?'+query unless !nil?(query)
    uri = URI.parse(BASE_URL+path)
  end

  def query(key,hash=params)
    val = hash[key] 
 puts "before: " + (key+'='+val)
    query = nil?(val) ? key+'='+urlencode(val) : ''
#query.gsub('%3D','=')
 puts "after: " + query
    #query.gsub(' ','+') 
   query 
  end

  def guid(guidstr)
    len = (guidstr||'').length #if not valid guid, return empty str
    return (len.eql?(32) ? guidstr : '') 
  end

  def nil?(obj)
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

  def urlencode(url)
URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) 
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
