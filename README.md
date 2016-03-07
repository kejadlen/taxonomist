# Taxonomist

# Getting Started

This setup assumes Postgres isn't already running in the background. If it
isn't, you can comment out the `postgres` process in the `Procfile`.

``` shell
git clone https://github.com/kejadlen/taxonomist.git
cd taxonomist
bundle install
```

## Database Setup

As you might expect, Postgres needs to be running to do the initial database
setup.

``` shell
createdb taxonomist
bundle exec rake db:migrate
```

## Running Taxonomist

Required environment variables for running Taxonomist:

- `DATABASE_URL`
- `RODA_SECRET`
- `TWITTER_API_KEY`, `TWITTER_API_SECRET`

``` shell
bundle exec foreman start
```

## Authentication

After starting Taxonomist, visit [http://localhost:9292](http://localhost:9292)
in the browser to get access tokens for your user.

## Fetching Data

Open a Taxonomist console with an existing user by running `bundle exec rake
console[USER_ID]`. `USER_ID` will generally be `1` assuming that the first
authed user is the one you want to fetch data for.

``` ruby
Jobs::UpdateUser.enqueue(user.id)
```
