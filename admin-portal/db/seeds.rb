# setting
Setting.create(type_name: 'SESSION_WEB', value: '240', description: 'Define the idle time before a session is automatically signed out.')
Setting.create(type_name: 'API_SERVER_URL', value: nil, description: 'Define the API Server URL.')
# Setting.create(type_name: 'API_SERVER_IP', value: nil, description: 'Define the private IP of all Client API Server instances.')

Role.create(type_name: 'Super Administrator')
Role.create(type_name: 'Administrator')
Role.create(type_name: 'Content Editor')

Product.create(name: 'Travel Insurance', code: 'travel', activation_status: true)
Product.create(name: 'Pet Insurance', code: 'pet', activation_status: false)
Product.create(name: 'Maid Insurance', code: 'maid', activation_status: false)
Product.create(name: 'Home Insurance', code: 'home', activation_status: false)
Product.create(name: 'Car Insurance', code: 'car', activation_status: false)
Product.create(name: 'International Health Insurance', code: 'international-health', activation_status: false)
Product.create(name: 'Personal Accident Insurance', code: 'personal-accident', activation_status: false)