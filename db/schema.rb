# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140221234457) do

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "models", force: true do |t|
    t.string "state", limit: nil
  end

  add_index "models", ["id"], name: "sqlite_autoindex_models_1", unique: true

  create_table "movies", force: true do |t|
    t.integer "year"
    t.string  "title",       limit: nil
    t.integer "tmdbid"
    t.string  "tmdbposter",  limit: nil
    t.string  "tmdbgenre",   limit: nil
    t.integer "ratingCount"
    t.float   "ratingAvg"
  end

  create_table "probes", id: false, force: true do |t|
    t.integer "movie"
    t.integer "customer"
    t.integer "rating"
    t.date    "date"
  end

  add_index "probes", ["customer"], name: "probe_customers"
  add_index "probes", ["movie"], name: "probe_movies"

  create_table "ratings", id: false, force: true do |t|
    t.integer "movie"
    t.integer "customer"
    t.integer "rating"
    t.date    "date"
  end

  add_index "ratings", ["customer"], name: "rating_customers"
  add_index "ratings", ["movie"], name: "rating_movies"

end
