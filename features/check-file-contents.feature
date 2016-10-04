Feature: Check files in a WordPress install

  Scenario: Check for use of eval(base64_decode()) in files
    Given a WP install

    When I run `wp doctor check file-eval`
    Then STDOUT should be a table containing rows:
      | name          | status    | message                                                       |
      | file-eval     | success   | All 'php' files passed check for 'eval\(.*base64_decode\(.*'. |

    Given a wp-content/mu-plugins/exploited.php file:
      """
      <?php
      eval( base64_decode( $_POST ) );
      """

    When I run `wp doctor check file-eval`
    Then STDOUT should be a table containing rows:
      | name          | status    | message                                                      |
      | file-eval     | error     | 1 'php' file failed check for 'eval\(.*base64_decode\(.*'.   |

  Scenario: Check for the use of sessions
    Given a WP install
    And a config.yml file:
      """
      file-sessions:
        check: File_Contents
        options:
          regex: .*(session_start|\$_SESSION).*
          only_wp_content: true
      """

    When I run `wp doctor check file-sessions --config=config.yml --format=json`
    Then STDOUT should be JSON containing:
      """
      [{"name":"file-sessions","status":"success","message":"All 'php' files passed check for '.*(session_start|\\$_SESSION).*'."}]
      """

    Given a wp-content/mu-plugins/sessions1.php file:
      """
      <?php
      session_start();
      """
    And a wp-content/mu-plugins/sessions2.php file:
      """
      <?php
      echo '';
      $_SESSION['foo'] = bar;
      """

    When I run `wp doctor check file-sessions --config=config.yml --format=json`
    Then STDOUT should be JSON containing:
      """
      [{"name":"file-sessions","status":"error","message":"2 'php' files failed check for '.*(session_start|\\$_SESSION).*'."}]
      """