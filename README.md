# uxweekly-automator
Automate UX Weekly stuff using Pinboard and Mailchimp. 

Download and install gems:

```bash
git pull git@github.com:simonv3/uxweekly-automator.git master
bundle install
```

in `config/env.yml` add:
```yaml
development:
  MAILCHIMP_API_KEY: 'abc'
  PINBOARD_USERNAME: 'user'
  PINBOARD_PASSWORD: 'password'
```

Then run
```bash
ruby auto.rb
```
