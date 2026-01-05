# Troubleshooting

Common issues and solutions when using RailsPress.

## Installation Issues

### "ActionText not installed" Error

**Symptom**: Error about missing ActionText or `has_rich_text` undefined.

**Solution**: Install ActionText before RailsPress:

```bash
bin/rails action_text:install
bin/rails db:migrate
```

Then install RailsPress:

```bash
bin/rails generate railspress:install
bin/rails db:migrate
```

### "ActiveStorage not configured" Error

**Symptom**: Header images fail to upload, or attachment-related errors.

**Solution**: Install and configure ActiveStorage:

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

Configure a storage service in `config/storage.yml` and set it in your environment:

```ruby
# config/environments/development.rb
config.active_storage.service = :local
```

### Rich Text Editor Not Loading

**Symptom**: Textarea appears instead of rich text editor; no formatting toolbar.

**Solution**: Ensure the Lexxy editor JavaScript is loaded. Check your importmap:

```ruby
# config/importmap.rb
pin "railspress", to: "railspress.js"
```

And include in your application.js:

```javascript
import "railspress"
```

### CSS Not Loading

**Symptom**: Admin interface appears unstyled or broken layout.

**Solution**: Include RailsPress stylesheets:

```erb
<%# app/views/layouts/application.html.erb %>
<%= stylesheet_link_tag "railspress/admin" %>
```

Or via asset pipeline:

```css
/* app/assets/stylesheets/application.css */
*= require railspress/admin
```

---

## Authentication Issues

### Admin is Publicly Accessible

**Symptom**: Anyone can access `/blog/admin` without authentication.

**Solution**: RailsPress does not include authentication. Add it to your application:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!, if: :railspress_admin?

  private

  def railspress_admin?
    request.path.start_with?("/blog/admin")
  end
end
```

See [CONFIGURING.md](CONFIGURING.md#adding-authentication) for more patterns.

### "current_user undefined" Error

**Symptom**: Error when `enable_authors` is set but `current_user` doesn't exist.

**Solution**: Set the correct author method for your authentication:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_authors
  config.current_author_method = :current_admin  # Match your auth system
end
```

Or use a proc:

```ruby
config.current_author_proc = -> { Current.user }
```

---

## Entity Issues

### Entity Not Appearing in Sidebar

**Symptom**: Registered entity doesn't show in admin navigation.

**Solution**: Ensure the entity is properly registered:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.register_entity :my_model
end
```

And the model includes the concern:

```ruby
# app/models/my_model.rb
class MyModel < ApplicationRecord
  include Railspress::Entity

  railspress_fields :title, :description
end
```

Restart the server after adding new entities.

### "Entity not found" Error

**Symptom**: 404 or "entity not found" when accessing entity routes.

**Causes and solutions**:

1. **Entity not registered**: Add to initializer (see above)
2. **URL uses wrong name**: Use pluralized, underscored model name (`team_members` not `TeamMember`)
3. **Model missing concern**: Add `include Railspress::Entity`

### Fields Not Detected Correctly

**Symptom**: Wrong field type rendered in form (e.g., text input instead of rich text).

**Solution**: Use explicit type declaration:

```ruby
railspress_fields :content, as: :rich_text
railspress_fields :published, as: :boolean
railspress_fields :tech_stack, as: :list
```

### Array Field Methods Undefined

**Symptom**: Error like `undefined method 'tech_stack_list='`.

**Cause**: Virtual attributes for `:list` and `:lines` fields are defined at class load time.

**Solution**: Restart your Rails server after adding new array field declarations.

### Changes to Model Not Reflected

**Symptom**: Updated `railspress_fields` not showing in forms.

**Solutions**:

1. Save the model file
2. Hard refresh the browser (not just Turbo navigation)
3. Check Rails server logs for syntax errors
4. Restart the server for array field changes

---

## Import/Export Issues

### Import Job Not Running

**Symptom**: Import stuck in "pending" status.

**Solution**: Ensure a background job processor is running:

```bash
# Sidekiq
bundle exec sidekiq

# Solid Queue (Rails 8+)
bin/rails solid_queue:start
```

### Export Download Returns 404

**Symptom**: "Download" link doesn't work after export completes.

**Causes**:

1. **Export failed**: Check the error_messages column
2. **ActiveStorage not configured**: Ensure storage service is set
3. **File was cleaned up**: Very old exports may have been purged

### Zip File Contains Wrong Content

**Symptom**: Export zip has wrong or missing files.

**Solution**: Check ActiveStorage configuration. For S3 or other cloud storage, ensure proper credentials and permissions.

### Import Creates Duplicate Posts

**Symptom**: Same posts imported multiple times.

**Solution**: RailsPress doesn't de-duplicate by default. Delete duplicates and re-import, or implement custom de-duplication:

```ruby
# Check for existing post before import
existing = Railspress::Post.find_by(slug: extracted_slug)
```

---

## Routing Issues

### Route Conflicts with Host App

**Symptom**: Host app routes not accessible, or RailsPress routes returning 404.

**Solution**: Check route order and engine mount path:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Host app routes first
  resources :admin  # This could conflict!

  # Mount RailsPress at specific path
  mount Railspress::Engine => "/cms", as: :railspress
end
```

Use a unique mount path to avoid conflicts.

### "undefined method 'railspress'" Error

**Symptom**: Route helpers like `railspress.admin_posts_path` fail.

**Solution**: Ensure the engine is properly mounted with an `as:` option:

```ruby
mount Railspress::Engine => "/blog", as: :railspress
```

The `as: :railspress` provides the `railspress.` route helper prefix.

---

## Display Issues

### Reading Time Shows Wrong Value

**Symptom**: Reading time displays incorrect or zero minutes.

**Solutions**:

1. Check `words_per_minute` configuration:
   ```ruby
   Railspress.configure do |config|
     config.words_per_minute = 200  # Default
   end
   ```

2. Ensure post has content (empty posts show 0 min)

3. For cached reading time, re-save the post to recalculate

### Header Images Not Displaying

**Symptom**: Image field works but images don't show on frontend.

**Solutions**:

1. **Use the helper**: `rp_featured_image_url(@post)`
2. **Check if attached**: `@post.header_image.attached?`
3. **Ensure feature is enabled**: `config.enable_post_images`
4. **Configure storage**: Ensure ActiveStorage service is properly configured

### Rich Text Content Displays as Plain Text

**Symptom**: HTML tags visible instead of formatted content.

**Solution**: Use the `content` accessor directly (it returns ActionText HTML):

```erb
<%# Correct %>
<%= @post.content %>

<%# Wrong (escapes HTML) %>
<%= @post.content.to_plain_text %>
```

---

## Performance Issues

### Slow Admin Page Load

**Symptom**: Entity index pages take long to load.

**Solutions**:

1. **Add pagination**: Entities automatically paginate at 20 per page
2. **Add database indexes**: Index frequently-filtered columns
3. **Reduce N+1 queries**: Add eager loading in your model:
   ```ruby
   scope :for_admin, -> { includes(:category, :tags) }
   ```

### Large Import Files Fail

**Symptom**: Timeout or memory errors during large imports.

**Solutions**:

1. Split into smaller zip files (100-200 posts each)
2. Increase worker memory/timeout
3. Process imports during off-peak hours

---

## Development Tips

### Debug Entity Configuration

```ruby
# Rails console
config = Project.railspress_config
config.fields        # => { title: { type: :string }, ... }
config.label         # => "Projects"
config.route_key     # => "projects"
```

### Check Registered Entities

```ruby
# Rails console
Railspress.registered_entities  # => [:project, :testimonial]
Railspress.entity_for("projects")  # => EntityConfig instance
```

### View Raw SQL

```ruby
# Rails console
Railspress::Post.published.ordered.to_sql
```

### Test Authentication

```bash
# Should redirect to login (if auth configured)
curl -I http://localhost:3000/blog/admin

# Check response code
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/blog/admin
```

---

## Getting Help

1. Check this troubleshooting guide
2. Search existing [GitHub issues](https://github.com/your-org/railspress/issues)
3. Review the [documentation](README.md)
4. Open a new issue with:
   - Rails version
   - RailsPress version
   - Error message and backtrace
   - Steps to reproduce
