# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180430100555) do

  create_table "admin_portal_delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "admin_portal_delayed_jobs_priority"
  end

  create_table "approvals", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "table"
    t.integer "row_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "content"
    t.string "user"
  end

  create_table "audits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "client_api_clients", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "client_api_id"
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_api_id"], name: "index_client_api_clients_on_client_api_id"
    t.index ["client_id"], name: "index_client_api_clients_on_client_id"
  end

  create_table "client_api_delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "client_api_delayed_jobs_priority"
  end

  create_table "client_api_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "client_id"
    t.string "client_api_key"
    t.integer "client_api_id"
    t.string "request_ip"
    t.string "request_endpoint"
    t.string "request_method"
    t.string "request_format"
    t.string "request_payload_format"
    t.text "request_payload"
    t.string "response_code"
    t.text "response_payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "client_apis", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.bigint "product_id"
    t.string "path"
    t.string "method"
    t.boolean "authorization", default: true
    t.text "payloads"
    t.string "derived_from"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "approve_create", default: false
    t.boolean "status", default: true
    t.boolean "validation", default: true
    t.boolean "activation_status", default: false
    t.index ["product_id"], name: "index_client_apis_on_product_id"
  end

  create_table "client_insurer_product_apis", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "client_id"
    t.bigint "insurer_product_api_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_insurer_product_apis_on_client_id"
    t.index ["insurer_product_api_id"], name: "index_client_insurer_product_apis_on_insurer_product_api_id"
  end

  create_table "clients", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.text "address"
    t.string "website_url"
    t.string "contact_person_name"
    t.string "contact_person_email"
    t.string "broker_code"
    t.string "billing_type"
    t.string "whitelisted_ip"
    t.integer "monthly_api_threshold"
    t.string "client_code"
    t.string "client_api_key"
    t.boolean "activation_status", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.string "contact_person_phone"
    t.boolean "status", default: true
    t.index ["client_api_key"], name: "index_clients_on_client_api_key"
    t.index ["client_code"], name: "index_clients_on_client_code"
  end

  create_table "cron_delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "cron_delayed_jobs_priority"
  end

  create_table "delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "insurer_clients", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "insurer_id"
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "product_id"
    t.index ["client_id"], name: "index_insurer_clients_on_client_id"
    t.index ["insurer_id"], name: "index_insurer_clients_on_insurer_id"
  end

  create_table "insurer_product_api_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "insurer_product_api_id"
    t.string "source"
    t.string "request_url"
    t.string "request_method"
    t.text "request_payload"
    t.string "response_code"
    t.text "response_payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "request_id"
    t.string "response_format"
    t.string "request_format"
  end

  create_table "insurer_product_apis", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.boolean "is_authentication", default: false
    t.string "auth_token_key_name"
    t.bigint "client_api_id"
    t.bigint "insurer_id"
    t.string "cache_policy"
    t.boolean "activation_status", default: false
    t.text "api_url"
    t.string "api_method"
    t.string "api_flavour"
    t.text "auth_scheme_name"
    t.text "credential"
    t.string "auth_api"
    t.string "payload_type"
    t.text "payload"
    t.text "RSA_encrypt_public_key"
    t.boolean "validation", default: true
    t.text "payload_validation"
    t.string "headers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "status", default: true
    t.integer "cache_timeout", default: 24
    t.index ["client_api_id"], name: "index_insurer_product_apis_on_client_api_id"
    t.index ["insurer_id"], name: "index_insurer_product_apis_on_insurer_id"
  end

  create_table "insurer_products", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "insurer_id"
    t.bigint "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["insurer_id"], name: "index_insurer_products_on_insurer_id"
    t.index ["product_id"], name: "index_insurer_products_on_product_id"
  end

  create_table "insurers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "company_name", null: false
    t.text "company_address"
    t.string "company_code", null: false
    t.string "website_url"
    t.boolean "activation_status", default: false
    t.string "contact_person_name", null: false
    t.string "contact_person_phone"
    t.string "contact_person_email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "company_phone"
    t.text "mapping"
    t.boolean "status", default: true
    t.index ["company_code"], name: "index_insurers_on_company_code"
  end

  create_table "mappings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.text "list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "status", default: true
  end

  create_table "products", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.boolean "activation_status", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "status", default: true
    t.index ["code"], name: "index_products_on_code"
  end

  create_table "response_caches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "insurer_product_api_id"
    t.text "payload_sha256"
    t.text "response"
    t.datetime "expired_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "request"
    t.text "url"
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "type_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "user_id"
    t.boolean "status", default: true
    t.string "platform", null: false
    t.string "browser"
    t.string "ip_address"
    t.datetime "expired_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "version"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "type_name"
    t.string "validation"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "value"
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "email", null: false
    t.boolean "activation_status", default: false
    t.string "reset_password_token"
    t.string "invitation_token"
    t.bigint "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_hash"
    t.datetime "reset_password_send_at"
    t.datetime "invitation_send_at"
    t.boolean "accept_invitation", default: false
    t.boolean "status", default: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

end
