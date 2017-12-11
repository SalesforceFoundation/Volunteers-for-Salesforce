class V4SWhateverPage
  include PageObject

  a(:recycle_bin, href: /UndeletePage/)
  button(:empty_org, title: "Empty your organization's recycle bin")
end
