

# ----------------------------------------------
# these methods allow the view to handle AJAX
# ----------------------------------------------

module RestHelper

  def ajax_button(action)
    button_to_remote action, {:url=>{:action=>action}}
  end

  def ajax_search()
    @options = ['All','None']
    render :inline => # render view 
    '<%form_remote_tag :url=>{:action=>:search_action} do %> 
     <%=hidden_field_tag "ctrl_action",""%>
     <%=text_field_tag("submit_text","Enter text here")%>
     <%=submit_tag "All", onClickEvent("ctrl_action","search_all") %>
     <%=submit_tag "Add", onClickEvent("ctrl_action","search_add") %>
     <%=submit_tag "Delete", onClickEvent("ctrl_action","search_delete")%><%end%>'
  end       

  def ajax_submit(action,fieldid,friendlytxt) 
    actionstr = action.inspect
    fieldidstr = fieldid.inspect
    infostr = friendlytxt.inspect 
    render :inline => # render view 
      '<%form_remote_tag :url=>{:action=>'+actionstr+'} do %> 
       <%=text_field_tag('+fieldidstr+','+infostr+')%>
       <%=submit_tag('+actionstr+')%><%end%>'
  end

  def ajax_poller()
    periodically_call_remote(:url=>{:action=>:poller}, :frequency => '5')#, :update => 'response_div')
  end

  def update(request,response)
    page.replace_html 'request_div',request
    page.replace_html 'response_div',response
  end

  def onClickEvent(key,val) {
    :onClick=>"$('"+key+"').value='"+val+"';"}
  end

end

