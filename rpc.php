<?php


kirby()->set('rpc', [
  'method' => 'rpc_unassign_page',
  'roles' => ['admin'],
  'action' => function ($pageUuid, $username) {
    $page = get_page_by_uuid($pageUuid);

    $user = kirby()->site()->users()->find($username);

    unassign_page($user, $page);

    return [];
  }
]);

kirby()->set('rpc', [
  'method' => 'rpc_assign_page_to_user',
  'roles' => ['admin'],
  'action' => function ($pageUuid, $username) {
    $user = kirby()->site()->users()->find($username);

    $page = get_page_by_uuid($pageUuid);

    assign_page_to_user($user, $page);

    return [];
  }
]);

kirby()->set('rpc', [
  'method' => 'rpc_mark_as_completed',
  'action' => function ($pageUuid) {
    $user = kirby()->site()->user();

    $page = get_page_by_uuid(intval($pageUuid));

    user_read_page($user, $page);

    return [];
  }
]);

kirby()->set('rpc', [
  'method' => 'rpc_get_users',
  'roles' => ['admin'],
  'action' => function ($pageUuid) {
    $users = kirby()->site()->users();

    $res = [];

    $page = get_page_by_uuid($pageUuid);

    foreach ($users as $user) {

      $is_assigned = page_assigned_to_user($user, $page);

      $done = $is_assigned && user_has_read_all_infobits($user, $page);

      if (!$is_assigned) {
        $status = 'unassigned';
      }
      else if ($done) {
        $status = 'done';
      }
      else {
        $status = 'incomplete';
      }

      $res[] = [
        'name' => $user->username(),
        'status' => $status
      ];

    }

    return $res;
  }
]);

kirby()->set('rpc', [
  'method' => 'user_field_add_page',
  'roles' => ['admin'],
  'action' => function ($username, $field, $pageUuid) {
    $user = kirby()->site()->users()->find($username);

    $page = get_page_by_uuid($pageUuid);

    Pagelist\add($user, $field, $page);
  }
]);

kirby()->set('rpc', [
  'method' => 'user_field_get_pages',
  'roles' => ['admin'],
  'action' => function ($username, $field) {
    $topics = kirby()
            ->site()
            ->index()
            ->filterBy('template', 'topic');

    $r = [];

    $user = kirby()->site()->users()->find($username);

    foreach ($topics as $topic) {

      $completedIds = Pagelist\ids($user, INFOBITS_FIELD);

      $infobits = $topic->children();

      $completed = 0;    

      foreach ($infobits as $infobit) {
        $uuid = $infobit->uuid()->value;

        if (in_array($uuid, $completedIds)) {
          $completed++;
        }
      }

      $r[] = [
        'title' => $topic->title()->value,
        'uuid' => $topic->uuid()->value,
        'active' => Pagelist\has($user, $field, $topic),
        'infobits' => $infobits->count(),
        'completed' => $completed
      ];

    }

    return $r;
  }
]);
             

kirby()->set('rpc', [
  'method' => 'user_field_remove_page',
  'roles' => ['admin'],
  'action' => function ($username, $field, $pageUuid) {
    $user = kirby()->site()->users()->find($username);

    $page = get_page_by_uuid($pageUuid);

    Pagelist\remove($user, $field, $page);  
  }
]);
