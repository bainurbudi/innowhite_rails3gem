class ApiController < ApplicationController
  require 'digest/sha1'
  before_filter :initialize_innowhite 

  ## testing api
  def index
    act = @innowhite.get_sessionsaa("active") rescue nil
    pst = @innowhite.get_sessionsaa("Past") rescue nil
    @active_sessions = act.nil? ? [] : act
    @past_sessions = pst.nil?? [] : pst
  end

  def create_room          
      render :update do |page|
        begin
        res = @innowhite.create_room(:user => params[:user])
        page.replace "result", "<div id='result'>room_id = #{res[:room_id]} and address = #{res[:address]}</div>"
        rescue
          page.call "alert", "wrong username"
        end
      end    
  end

  def get_sessions
    @res = @innowhite.get_sessions
    render :update do |page|      
        page.replace "result-active", "<div id='result-active'>#{@res}</div>"
      end    
  end

  def past_sessions
    @res = @innowhite.get_sessions

    render :update do |page|
        page.replace "result-past", "<div id='result-past'>#{@res}</div>"
    end
  end

  def join_room    
    res = @innowhite.join_meeting(params[:room_id], params[:user])

    render :update do |page|
      page.replace "result-room", "<div id='result-room'>#{res}</div>"
    end
  end

  def create_room_info
    @meeting = WebSession.new
    @user = User.find_by_login(params[:user])
    Time.zone = @user.time_zone.nil? ? "UTC" : @user.time_zone
    @meeting.start_at = Time.zone.now
    @meeting.session_id = params[:roomId]
    @meeting.tag_list = params[:tags].split(',')
    @meeting.session_desc =  params[:desc]
    @join_address = "http://innowhite.com/create_join_room/#{@web_session.session_id}"
    UserMailer.deliver_send_invitation_session_self(@user,@user.email, params[:address],@web_session,@join_address)
    @meeting.save!

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @meeting }
    end
  end

  def initialize_innowhite
    @innowhite = Innowhite.new
  end

end
