class TestsController < ApplicationController

  layout "standard"

  before_filter :init_forms

  before_filter :init_menu

  # does not work in initialize
  def init_menu
    @menus.set_selected("tests")
  end


  protected

  # language could not be set yet in ititialize so we use a filter
  def init_forms
    @fw = FrameWork.new
    @ir = InterfaceResults.new

    @optgroup = "test_packaging"
    init_fields
  end

  def init_fields
    ### USERS MANAGEMENT ###
    @fo = @fw.add_form("test_packaging")

    @fi = @fo.add_field("from_full_name", "text", { "autofocus" => true, "required" => true, "size" => 40 })
    @fi = @fo.add_field("from_email_address", "text", { "required" => true, "realtype" => "email", "size" => 40 })
    @fi = @fo.add_field("username", "text", { "required" => true, "size" => 40 })
    @fi = @fo.add_field("password", "password", { "required" => true, "size" => 40 })
    @fi = @fo.add_field("password_verif", "password", { "required" => true, "size" => 40 })
    @fi.verification_field = "password"
  end

  public

  def list
    flash[:error] = nil

    # FOR DEV ONLY
    if in_dev?
      @fw.forms[@optgroup].fields["from_full_name"].value = TESTS_FULL_NAME
      @fw.forms[@optgroup].fields["from_email_address"].value = TESTS_EMAIL_ADDRESS
      @fw.forms[@optgroup].fields["username"].value = TESTS_KPS_USERNAME
      @fw.forms[@optgroup].fields["password"].value = TESTS_KPS_PASSWORD
      @fw.forms[@optgroup].fields["password_verif"].value = TESTS_KPS_PASSWORD
    end
    if ! session["test_packaging"].nil?
      @fw.forms[@optgroup].fields["from_full_name"].value = session["test_packaging"]["from_full_name"]
      @fw.forms[@optgroup].fields["from_email_address"].value = session["test_packaging"]["from_email_address"]
      @fw.forms[@optgroup].fields["username"].value = session["test_packaging"]["username"]
      # don't leak passwords in case user didn't close it's session
      #  @fw.forms[@optgroup].fields["password"].value = session["test_packaging"]["password"]
      #  @fw.forms[@optgroup].fields["password_verif"].value = session["test_packaging"]["password_verif"]
    end
  end

  def test
    flash[:error] = nil

    # validate form inputs
    @fw.form_validate(@optgroup, params)
    if @fw.forms[@optgroup].error
      render :action => "list"
      return
    end

    @pipe_results = [] # used in view

    # Packaging test
    pipe_result = test_packaging
    @pipe_results.push(pipe_result) # used in view
    pipe_result.debug_interface_result(@ir)

    if pipe_result.status == 0
      KLOGGER.info GT_("logs.tests.packaging.succeed")
      #c = ConfigOptions.new
      #c.get_match(/^ldap\./).each do |key, value|
      #  message = "debug: config option: '#{key.to_s}' = '#{value.to_s}'"
      #  KLOGGER.debug message
      #end
    else
      KLOGGER.info GT_("logs.tests.packaging.failed")
      c = ConfigOptions.new
      c.get_match(/^ldap\./).each do |key, value|
        message = "debug: config option: '#{key.to_s}' = '#{value.to_s}'"
        KLOGGER.debug message
      end
      @ir.get_values("debug").each do |message|
        message = "debug: " + message
        KLOGGER.debug message
      end

      # FOR DEV ONLY
      if in_dev?
        flash[:error] = "<pre style='text-align:left;'>" + @ir.get_values("debug").join("\n") + "</pre>"
      end
    end
  end
end

# LOGIN test
def test_login()
  comment = "Login test"

  test_file = TESTS_KPSLOGIN_FILE

  test_host = TESTS_KPS_HOST
  test_port = kps_config.get("server.port")

  test_username = params[:username]
  test_password = params[:password]

  # parameters
  test_params = []

  test_params.push("-u")
  test_params.push(test_username)
  test_params.push("-w")
  test_params.push(test_password)
  test_params.push("-h")
  test_params.push(test_host)
  test_params.push("-p")
  test_params.push(test_port)

  # run program
  p = PipeExec.new
  pipe_result = p.pipe_exec(comment=comment,
                            exec_file=test_file,
                            cmd_params=test_params,
                            stdin="")

  return pipe_result
end


# PACKAGING test
def test_packaging()
  comment = GTEH_("tests.packaging_test")

  ### GET PARAMETERS ###
  kps_config = ConfigOptions.new

  test_file = TESTS_PKGMAIL_FILE

  test_pkg_type = TESTS_PKG_TYPE
  test_license = TESTS_LICENSE

  test_subject = TESTS_SUBJECT

  test_to = TESTS_TO
  test_cc = TESTS_CC

  test_host = TESTS_KPS_HOST
  test_port = kps_config.get("server.port")
  if ! TESTS_KPS_PORT.nil? && TESTS_KPS_PORT.to_s != ""
    test_port = TESTS_KPS_PORT
  end

  session["test_packaging"] = {}
  test_username = session["test_packaging"]["username"] = params[:username]
  test_password = session["test_packaging"]["password"] = params[:password]
  session["test_packaging"]["password_verif"] = params[:password_verif]
  full_name = session["test_packaging"]["from_full_name"] = params[:from_full_name]
  email_address = session["test_packaging"]["from_email_address"] = params[:from_email_address]

  ### prepare configuration data for running the test tool ###

  output = ""

  # create config that will be sent as parameters to test program
  parameters = {}
  parameters["server"] = test_host
  parameters["port"] = test_port

  parameters["pkg_type"] = test_pkg_type
  parameters["license"] = test_license

  parameters["username"] = test_username
  parameters["password"] = test_password
  parameters["from_name"] = full_name
  parameters["from_addr"] = email_address
  parameters["subject"] = "lalalala"  
  parameters["to"] = test_to
  parameters["cc"] = test_cc
  parameters["pkg_type"] = test_pkg_type
  parameters["dontmail"] = "yes"

  test_params = []
  parameters.each do |key, value|
    output += "#{key} #{value.to_s}\n"
  end

  # create config and message that will be sent to stdin of test program
  output += "username " + test_username + "\n"
  output += "password " + test_password + "\n"
  output += "end\n"
  output += "This is a test message (line 1).\n"
  output += "This is a test message (line 2).\n"
  output += "This is a test message (line 3).\n"

  p = PipeExec.new
  pipe_result = p.pipe_exec(comment=comment,
                            exec_file=test_file,
                            cmd_params=test_params,
                            stdin=output)

  return pipe_result
end


