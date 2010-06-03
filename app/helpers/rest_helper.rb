

# ----------------------------------------------
# these methods allow the view to handle AJAX
# ----------------------------------------------

module RestHelper

  def ajax_button(action)
    button_to_remote action, build_args(action)
  end

  def ajax_submit(action,fieldid,friendlytxt) 
    actionstr = action.inspect
    fieldidstr = fieldid.inspect
    infostr = friendlytxt.inspect 
    render :inline => # render view 
      '<% form_remote_tag build_args('+actionstr+') do %>
       <%=text_field_tag('+fieldidstr+','+infostr+')%>
       <%=submit_tag('+actionstr+')%><%end%>'
  end

  def build_args(action,method='get') {
    :method=>method,
    :url=>{:action=>action}}
  end

  def update(request,response)
    page.replace_html 'request_div',request
    page.replace_html 'response_div',response
  end

end

