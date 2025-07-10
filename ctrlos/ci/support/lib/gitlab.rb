module GitLab
  extend self

  def curl(*args)
    slurp(
      "curl",
      "--header", "PRIVATE-TOKEN:#{SCHEDULED_TASKS_TOKEN}",
      "--location",
      "--silent",
      *args,
    )
  end

  def to_query_string(parameters)
    parameters
      .transform_values { |param| URI.encode_uri_component(param) }
      .map { |name, value| [ name, value ].join("=") }
      .join("&")
  end

  def get(url)
    JSON.parse(curl("--request", "GET", url))
  end

  def post(url, body)
    JSON.parse(curl("--request", "POST", url, "--json", body.to_json()))
  end

  def put(url, body)
    JSON.parse(curl("--request", "PUT", url, "--json", body.to_json()))
  end

  def branch(branch_name)
    branch_name = URI.encode_uri_component(branch_name)
    get("https://#{CI_SERVER_HOST}/api/v4/projects/#{CI_PROJECT_ID}/repository/branches/#{branch_name}")
  end

  def merge_requests(source_branch: nil, state: nil)
    parameters = {}
    if source_branch
      parameters[:source_branch] = source_branch
    end
    if state
      parameters[:state] = state
    end

    parameters = to_query_string(parameters)
    get("https://#{CI_SERVER_HOST}/api/v4/projects/#{CI_PROJECT_ID}/merge_requests?#{parameters}")
  end

  def create_merge_request(merge_request)
    post("https://#{CI_SERVER_HOST}/api/v4/projects/#{CI_PROJECT_ID}/merge_requests", merge_request)
  end

  def update_merge_request(merge_request)
    iid = merge_request["iid"]
    put("https://#{CI_SERVER_HOST}/api/v4/projects/#{CI_PROJECT_ID}/merge_requests/#{iid}", merge_request)
  end
end
