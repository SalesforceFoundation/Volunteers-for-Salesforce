module Sfdo_api_v4s
  require 'time'
  # NPSP will automatically create certain fields on certain objects based on required input values for those records.
  # There is no way to know in advance from the API which these are, so we find them empirically and note them here
  # before calling the create() method in SfdoAPI
  @fields_acceptibly_nil = { 'Contact': ['Name'],
                             'Opportunity': ['ForecastCategory'] }

  def create_contact_with_criteria(client_name, status = '', avail = '', skills = '')
    @contact_id = create 'Contact', LastName: client_name,
                         Volunteer_Status: status,
                         Volunteer_Availability: avail,
                         Volunteer_Skills: skills
    @contact_name = client_name
    account_object = select_api "select AccountId from Contact where Id = '#{@contact_id}'"
    my_account_object = account_object.first
    @account_id_for_contact = my_account_object.AccountId
    @array_of_contacts << @contact_id
  end

  def create_campaign(camp_name)
    @campaign_id = create 'Campaign', Name: "#{camp_name} #{@random_string}",
                                      IsActive: true
  end

  def create_job_campaign
    @job_id = create 'Volunteer_Job' , Campaign: @campaign_id,
                     Description: 'job_description',
                     Display_on_Website: true
  end

  def create_shift_for_job
    event_time = Time.now.utc.iso8601
    @shift_id = create 'Volunteer_Shift', Volunteer_Job: @job_id,
                       Description: 'shift_description',
                       Duration: 3,
                       Start_Date_Time: event_time
  end

  def delete_jobs
    api_client do
      jobs = select_api 'select Id from Volunteer_Job'
      jobs.each do |job_id|
        @api_client.destroy(job_id.sobject_type, job_id.Id)
      end
    end
  end

  def delete_campaigns
  api_client do
    camps = select_api 'select Id from Campaign'
    camps.each do |camp_id|
      @api_client.destroy(camp_id.sobject_type, camp_id.Id)
    end
  end
end

  def delete_all_contacts
    api_client do
      cts = select_api 'select Id from Contact'
      cts.each do |cts_id|
        @api_client.destroy(cts_id.sobject_type, cts_id.Id)
      end
    end
  end

  def set_url_and_object_namespace_to_v4s
    case ENV['TARGET_ORG']
      when 'unmanaged'
        interim_url = $instance_url.sub('https://', 'https://c.')
        $target_org_url = interim_url.sub('salesforce.com', 'visual.force.com')
        $object_namespace = ''
      when 'gs0'
        $target_org_url = $instance_url.sub('gs0.salesforce.com', 'gw-volunteers.gus.visual.force.com')
        $object_namespace = 'v4s__'
      else

        #THE MOST COMMON CASE, MANAGED CODE IN A DEVELOPMENT ORG
        # MyDomain example: https://ability-momentum-7120-dev-ed.cs70.my.salesforce.com
        #     becomes: https://ability-momentum-7120-dev-ed--npsp.cs70.visual.force.com
        # Pod example: https://na35.salesforce.com
        #     becomes: https://gw-volunteers.na35.salesforce.com
        if $instance_url.include? "my.salesforce.com"
          $target_org_url = $instance_url.gsub(/https:\/\/([\w-]+)\.(\w+)\.my.salesforce.com/, 'https://\1--gw-volunteers.\2.visual.force.com')
        else
          interim_url = $instance_url.sub('https://', 'https://gw-volunteers.')
          $target_org_url = interim_url.sub('my.salesforce.com', 'visual.force.com')
          $target_org_url = interim_url.sub('salesforce.com', 'visual.force.com')
        end

    end
  end

  def login_with_oauth
    require 'faraday'

    if ENV['SF_ACCESS_TOKEN'] and ENV['SF_INSTANCE_URL']
      $instance_url = ENV['SF_INSTANCE_URL']
      @access_token = ENV['SF_ACCESS_TOKEN']
    else
      conn = Faraday.new(url: ENV['SF_SERVERURL']) do |faraday|
        faraday.request :url_encoded # form-encode POST params
        # faraday.response :logger                  # log requests to STDOUT
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end

      response = conn.post '/services/oauth2/token',
                           grant_type: 'refresh_token',
                           client_id: ENV['SF_CLIENT_KEY'],
                           client_secret: ENV['SF_CLIENT_SECRET'],
                           refresh_token: ENV['SF_REFRESH_TOKEN']

      response_body = JSON.parse(response.body)
      @access_token = response_body['access_token']
      $instance_url = response_body['instance_url']
    end

    @browser.goto($instance_url + '/secur/frontdoor.jsp?sid=' + @access_token)
  end
end
