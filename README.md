# RubyOnRailsProject
A repo for ruby on rails project coursework

Tommy: Added devise gem in Gemfile
More about Devise:
- devise is one of those specific Lego kits. It's a very popular Gem whose only job is to handle user accounts.
- It automatically provides all the code needed for:
    User registration (sign-up forms)
    User login (sign-in forms)
    User logout
    "Forgot my password" functionality
- Because the project uses the devise Gem, don't have to code any of that yourself.

# Run the application
- Install any missing gem:
    ```bash
    bundle install 
    ```
- Run the pending migrations:
    ```bash
    bin/rails db:migrate
    ```
- Start the application server:
    ```bash
    bin/rails server
    ```
- Access the application via the link: http://localhost:3000