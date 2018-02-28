<?php


/**
 * @param User $user
 * @param Page $page
 * @return stdClass or false
 */
function get_topics_rec(User $user, Page $page) {

  switch ($page->template()) {

  case 'infobit':
    throw new Exception('unexpected infobit' . $page->id());

  case 'topic':
    $r = new stdClass;
    $r->type = 'topic';
    $r->id = $page->id();
    $r->title = $page->title()->value;
    $r->uuid = $page->uuid()->value;
    $r->active = Pagelist\has($user, TOPICS_FIELD, $page);
    $r->size = $page->children()->count();
    $r->done = 0;
    foreach ($page->children() as $child) {
      if (Pagelist\has($user, INFOBITS_FIELD, $child)) {
        $r->done++;
      }
    }
    return $r;
    break;

  default:
    $children = [];

    foreach ($page->children() as $child) {
      
      $tree = get_topics_rec($user, $child);

      if ($tree) {
        $children[] = $tree;
      } 
    }

    if (0 < count($children)) {
      $node = new stdClass;
      $node->type = 'node';
      $node->id = $page->id();
      $node->children = $children;
      $node->title = $page->title()->value;
      return $node;
    }
    else {
      return false;
    }
  }
}


kirby()->set('rpc', [
  'method' => 'get_topics',
  'roles' => ['admin'],
  'action' => function ($username) {
    
    $user = kirby()->site()->users()->find($username);

    $rootPage = kirby()->site();

    return get_topics_rec($user, $rootPage);
  }
]);

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

    $page = get_page_by_uuid($pageUuid);

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
  'method' => 'user_field_remove_page',
  'roles' => ['admin'],
  'action' => function ($username, $field, $pageUuid) {
    $user = kirby()->site()->users()->find($username);

    $page = get_page_by_uuid($pageUuid);

    Pagelist\remove($user, $field, $page);  
  }
]);

kirby()->set('rpc', [
  'method' => 'topic_get_infobits',
  'roles' => ['admin'],
  'action' => function ($username, $topicId) {
    $user = kirby()->site()->users()->find($username);

    $topic = kirby()->site()->index()->find($topicId);

    $result = [];

    foreach ($topic->children() as $infobit) {
      
      $t = new stdClass;
      $t->title = $infobit->title()->value;
      $t->id = $infobit->id();
      $t->done = has_read_infobit($user, $infobit);

      $result[] = $t;
    }

    return $result;
  }
]);

kirby()->set('rpc', [
  'method' => 'get_users',
  'roles' => ['admin'],
  'action' => function () {
    $res = [];

    $completed = [];
    $incomplete = [];

    foreach (get_topics() as $topic) {

      if (0 === $topic->children()->count()) continue;

      foreach (kirby()->site()->users()->data as $user) {

        $assigned = page_assigned_to_user($user, $topic);

        if ($assigned) {

          $done = user_has_read_all_infobits($user, $topic);

          if ($done) {
            $crnt = array_key_exists($user->username, $completed)
                  ? $completed[$user->username]
                  : 0;

            $completed[$user->username] = $crnt + 1;
          }
          else {
            $crnt = array_key_exists($user->username, $incomplete)
                  ? $incomplete[$user->username]
                  : 0;

            $incomplete[$user->username] = $crnt + 1;
          }

        }
      }
    }


    foreach (kirby()->site()->users()->data as $user) {
      $r = new stdClass;
      $r->name = $user->username;
      $r->completed = array_key_exists($user->username, $completed)
                    ? $completed[$user->username]
                    : 0;
      $r->incomplete = array_key_exists($user->username, $incomplete)
                     ? $incomplete[$user->username]
                     : 0;

      if (0 < $r->incomplete) {
        $res[] = $r;
      }
    }

    return $res;
  }
]);