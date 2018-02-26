<?php

define('KIRBY_ASSIGNMENTS_UUID', 'uuid');

define('TOPICS_FIELD', 'assignments');
define('INFOBITS_FIELD', 'pages_read');

require_once __DIR__ . '/pagelist.php';
require_once __DIR__ . '/lib.php';
require_once __DIR__ . '/rpc.php';


// Register a hook that generates a UUID when a page with
// a UUID field is created
kirby()->hook('panel.page.create', function ($page) {
  if ($page->content()->has(KIRBY_ASSIGNMENTS_UUID)) {
    $page->update([
      KIRBY_ASSIGNMENTS_UUID => generate_page_uuid($page)
    ]);
  }
});

kirby()->set('field', 'pageslist', __DIR__ . '/fields/pageslist');
kirby()->set('field', 'assignable', __DIR__ . '/fields/assignable');
kirby()->set('snippet', 'my-assignments', __DIR__ . '/snippets/my-assignments.php');