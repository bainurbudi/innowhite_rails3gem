class ApiController < ApplicationController
  require 'digest/sha1'
  before_filter :initialize_innowhite 

  #  ## testing api
  #  def index
  #    act = @innowhite.get_sessionsaa("active") rescue nil
  #    pst = @innowhite.get_sessionsaa("Past") rescue nil
  #    @active_sessions = act.nil? ? [] : act
  #    @past_sessions = pst.nil?? [] : pst
  #  end
  #
  #  def create_room
  #      render :update do |page|
  #        begin
  #        res = @innowhite.create_room(:user => params[:user])
  #        page.replace "result", "<div id='result'>room_id = #{res[:room_id]} and address = #{res[:address]}</div>"
  #        rescue
  #          page.call "alert", "wrong username"
  #        end
  #      end
  #  end
  #
  #  def get_sessions
  #    @res = @innowhite.get_sessions
  #    render :update do |page|
  #        page.replace "result-active", "<div id='result-active'>#{@res}</div>"
  #      end
  #  end
  #
  #  def past_sessions
  #    @res = @innowhite.get_sessions
  #
  #    render :update do |page|
  #        page.replace "result-past", "<div id='result-past'>#{@res}</div>"
  #    end
  #  end
  #
  #  def join_room
  #    res = @innowhite.join_meeting(params[:room_id], params[:user])
  #
  #    render :update do |page|
  #      page.replace "result-room", "<div id='result-room'>#{res}</div>"
  #    end
  #  end
  #
  #  def create_room_info
  #    @meeting = WebSession.new
  #    @user = User.find_by_login(params[:user])
  #    Time.zone = @user.time_zone.nil? ? "UTC" : @user.time_zone
  #    @meeting.start_at = Time.zone.now
  #    @meeting.session_id = params[:roomId]
  #    @meeting.tag_list = params[:tags].split(',')
  #    @meeting.session_desc =  params[:desc]
  #    @join_address = "http://innowhite.com/create_join_room/#{@web_session.session_id}"
  #    UserMailer.deliver_send_invitation_session_self(@user,@user.email, params[:address],@web_session,@join_address)
  #    @meeting.save!
  #
  #    respond_to do |format|
  #      format.html # index.html.erb
  #      format.xml  { render :xml => @meeting }
  #    end
  #  end
  #
  #  def initialize_innowhite
  #    @innowhite = Innowhite.new
  #  end

  ## testing api
  def index
    act = @innowhite.get_sessionsaa("active") rescue nil
    pst = @innowhite.get_sessionsaa("Past") rescue nil

    @active_sessions = act.nil? ? [] : act
    @past_sessions = pst.nil?? [] : pst
  end

  def create_room
    innowhite = Innowhite.new(params[:user],"abc")
    res = innowhite.create_room(:orgName => '', :user => params['username'])[:address] #rescue nil

    render :update do |page|
      page.replace "result", "<div id='result'>room_id = #{res[:room_id]} and address = #{res[:address]}</div>"
    end
  end

  def join_room
    innowhite = Innowhite.new(params[:user],"abc")
    res = innowhite.join_meeting(params[:room_id], params[:user])

    render :update do |page|
      page.replace "result-room", "<div id='result-room'>#{res}</div>"
    end
  end

  def exist_session
    begin
      @room_id = params[:roomId]
      @user = params[:user]
      @room = WebSession.find(:first, :conditions => ["session_id = ? and ((start_at < now() and end_at is null) or session_status = 'Active')",@room_id])

      respond_to do |format|
        format.xml  { render :xml => @room }
      end
    rescue
      @room = WebSession.new

      respond_to do |format|
        format.xml  { render :xml =>  @room.errors}
      end
    end
  end

  def past_sessions
    conditions = []
    @org_name = params[:orgName]
    @tags = params[:tags]
    @user = User.find_by_login(params[:user]) rescue nil

    Time.zone = @user.nil?? "UTC" : @user.time_zone
    conditions << "user_id = #{@user.id}" if @user
    conditions << "(organization_name = '#{@org_name}' or organization_name is null)"
    conditions << "session_status != 'Active'"

    conditions = conditions.join(" and ")

    @meetings = if @tags.blank?
      WebSession.find(:all, :conditions => conditions)
    else
      WebSession.find_tagged_with(@tags, :conditions => conditions)
    end

    respond_to do |format|
      format.xml  { render :xml => @meetings }
    end
  end

  def create_schedule_meeting
    @errors = []
    @meeting = WebSession.new
    @user = User.find_by_login(params[:user])

    @meeting.start_at = Time.zone.now
    @meeting.session_id = params[:roomId]
    @meeting.user_id = @user.id
    @meeting.session_start_date = Time.at(params[:startTime])
    @meeting.session_end_date = Time.at(params[:endTime])
    @meeting.start_at = Time.at(params[:startTime])
    @meeting.session_status = "Active"
    @meeting.tag_list = params[:tags].split(',')
    @meeting.session_name =  params[:desc]
    @meeting.session_url =  params[:address]
    @meeting.session_desc =  params[:desc]
    @meeting.organization_name =  params[:orgName]
    @join_address = "http://innowhite.com/create_join_room/#{@meeting.session_id}"
    #UserMailer.deliver_send_invitation_session_self(@user,@user.email, params[:address],@web_session,@join_address)
    @meeting.save!
  end

  def create_room_info
    begin
      #return "You have to passed the right arguments !" unless params[:user].blank? or params[:roomId].blank?
      @errors = []
      @meeting = WebSession.new
      @user = User.find_by_login(params[:user])

      Time.zone = (@user.time_zone.nil? ? "UTC" : @user.time_zone) if @user

      @meeting.start_at = Time.zone.now
      @meeting.session_id = params[:roomId]
      @meeting.user_id = @user.id if @user
      @meeting.session_status = "Active"
      @meeting.tag_list = params[:tags].split(',')
      @meeting.session_name =  params[:desc]
      @meeting.session_url =  params[:address]
      @meeting.session_desc =  params[:desc]
      @meeting.organization_name =  params[:orgName]
      @join_address = "http://innowhite.com/create_join_room/#{@meeting.session_id}"
      #UserMailer.deliver_send_invitation_session_self(@user,@user.email, params[:address],@web_session,@join_address)
      @meeting.save!

      respond_to do |format|
        format.xml  { render :xml => @meeting }
      end
    rescue
      return false
    end
  end

  def get_scheduled_sessions
    tags = params[:tags] if params[:tags]

    @meetings = unless params[:tags].blank?
      WebSession.later.find_tagged_with(tags)
    else
      WebSession.today.later.org(params[:orgName]).find(:all)
    end

    respond_to do |format|
      format.xml  { render :xml => @meetings }
    end
  end

  def update_scheduled_session
    meeting = WebSession.find_by_session_id(params[:roomId])
    meeting.start_at = Time.at(params[:startTime].to_i / 1000) if params[:startTime]
    meeting.end_at = Time.at(params[:endTime].to_i / 1000) if params[:endTime]
    meeting.session_desc = params[:description] if params[:description]
    meeting.tag_list = params[:tags] if params[:tags]

    meeting.save!

    respond_to do |format|
      format.xml  { render :xml => meeting }
    end
  end

  def cancel_meeting
    begin
      meeting = WebSession.find_by_session_id(params[:roomId])

      if meeting.destroy
        respond_to do |format|
          format.xml  { render :xml => "<success>true</success>" }
        end
      end
    rescue
      respond_to do |format|
        format.xml  { render :xml => "<success>Failed to cancel..</success>" }
      end
    end
  end

  def meeting_detail
    @meeting = WebSession.find_by_session_id(params[:id])

    respond_to do |format|
      format.html { render :nothing => true}
      format.xml  { render :xml => @meeting}
    end
  end

  def try_it
    if request.xhr?
      innowhite = Innowhite.new

      render :update do |page|
        case params[:kind]
        when 'show_menu'
          page.replace_html 'menu-area', :partial => "api/testing/menu.html"
        when 'create_room'
          address = innowhite.create_room(:orgName => '', :user => params['username'])[:address] #rescue nil

          page.replace_html('results-area', (address.blank? ? "We are experiencing the problem, please try again." : ({:partial => "api/testing/new_room_detail.html", :locals => {:address => address, :title => "Your room already created sucessfully."}})))
        when 'live_rooms'
          #          rooms = innowhite.get_sessions(:orgName => params['org_name']) rescue []
          rooms = innowhite.get_sessions(:orgName => nil) rescue []

          page.replace_html 'results-area', :partial => "api/testing/room_list.html", :locals => {:rooms => rooms, :as_link => false, :title => "The existing live rooms on the system."}
        when 'past_rooms'
          #          rooms = innowhite.past_sessions(:orgName => params['org_name']) rescue []
          rooms = innowhite.past_sessions(:orgName => nil) #rescue []

          page.replace_html 'results-area', :partial => "api/testing/room_list.html", :locals => {:rooms => rooms, :as_link => false, :title => "The existing past rooms on the system."}
        when 'exist_rooms_to_join'
          rooms = innowhite.get_sessions(:orgName => nil) rescue []

          page.replace_html 'results-area', :partial => "api/testing/room_list.html", :locals => {:rooms => rooms, :as_link => true, :title => "The existing room that available for you to join. Click the ID below to join the room."}
        when 'join_room'
          address = innowhite.join_meeting(params[:room_id], params[:username])# rescue nil

          #          page.replace_html 'results-area', (address.blank? ? "We are experiencing the problem, please try again." : "<br/>You join the Room ID #{params[:room_id]} successfully. <br/> The url to access the room : <br/><a href='#{address}' target='_blank'>#{address}</a>")
          page.replace_html('results-area', (address.blank? ? "We are experiencing the problem, please try again." : ({:partial => "api/testing/new_room_detail.html", :locals => {:address => address, :title => "You join the Room ID #{params[:room_id]} successfully"}})))
        when 'schedule_room'
          address = innowhite.schedule_meeting(:user => params[:username], :orgName => nil) rescue nil

          page.replace_html 'results-area', (address.blank? ? "We are experiencing the problem, please try again." : "<br/>You successfully scheduling new room. <br/>The url to access the room : <br/><a href='#{address}' target='_blank'>#{address}</a>")
        end
      end
    end
  end



  private

  def pass_authenticate_backup
    begin
      org = params[:orgName]
      org ||= params[:parentOrg]
      checksum_tmp = "parentOrg=#{params[:parentOrg]}&orgName=#{params[:orgName]}"
      auth = PkStorage.first(:conditions => ["organization_name = ?",org]) rescue nil
      checksum = Digest::SHA1.hexdigest(URI.parse(checksum_tmp+auth.private_key).to_s)

      if checksum.eql?(params[:checksum])
        return true
      else
        raise "authentication failed"
      end
    rescue
      raise "organization #{org} is not found"
    end
  end

  def pass_authenticate
    Digest::SHA1.hexdigest("#{params[:orgName]}"+"innowhite"+"#{params[:private]}")
  end


end
