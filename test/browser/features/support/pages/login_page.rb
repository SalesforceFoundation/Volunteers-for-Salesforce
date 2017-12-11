class LoginPage
  include PageObject

  div(:app_switcher, id: 'tsid')
  a(:v4s_app_picker, text: 'Volunteers')
end

