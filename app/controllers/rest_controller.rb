require 'json'
require 'rubygems'
require 'oauth'
require 'oauth/consumer'
require 'etc'

class RestController < ApplicationController

  BASE_URL = 'http://localhost:45100/remote' 
  SECRET_FILE = 'restaccess.txt'
 
  LIB_URL   = '/library'
  FILE_URL = '/files'
  SRCH_URL = '/search'

  #------------------ handlers ------------------ 

  def hello
    send_request '/hello'
  end

  def files
    send_request LIB_URL+FILE_URL
  end

  def search
    guid = guid(params[:guid])
    filepath = set?(guid) ? '/'+guid+'/files' : '' 
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

  #------------------- helpers -_-----------------

  def send_request(path)
    begin
      uri = uri(path)
      getreq = Net::HTTP::Get.new(uri.path)
      sign_request!(getreq)
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
      sign_request!(delreq)
      resp = start_request(delreq,uri)
      render_page(delreq,resp,uri)
    rescue Exception => e
      render_exception(e.to_s,delreq,uri)
     end
  end

  def send_post(path,query)
    begin
      raise Exception,'you must type a query!' unless set?(query)
      uri = uri(path,query)
      postreq = Net::HTTP::Post.new(uri.request_uri)
      postreq.set_form_data(uri.query) 
      postreq['content-type'] = 'UTF-8'
      sign_request!(postreq)
      resp = start_request(postreq,uri)
      render_page(postreq,resp,uri)
    rescue Exception => e
      render_exception(e.to_s,postreq,uri)
    end
  end

  def start_request(req,uri) 
    resp = Net::HTTP::start(uri.host,uri.port) { |http|
      http.request(req); }
  end

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
 
  def uri(path,query=nil)
    path << '?'+query unless !set?(query)
    uri = URI.parse(BASE_URL+path)
  end

  def query(key,hash=params)
    val = hash[key] 
    query = set?(val) ? key+'='+val : ''
    query.gsub(' ','+') 
  end

  def guid(guidstr)
    len = (guidstr||'').length #if not valid guid, return empty str
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
