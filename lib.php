<?php

/**
 * Generates a uuid.
 * @return string
 */
function generate_page_uuid() {
  return strval(random_int(2**10, 2**31));
}

/**
 * Retrieves a page by uuid or raises an Exception
 * @param string $uuid
 * @return Page
 */
function get_page_by_uuid($uuid) {
  return kirby()
    ->site()
    ->index()
    //->filterBy('template', 'topic')
    ->firstWhere(function ($page) use ($uuid) {
      return $page->uuid()->value == $uuid;
    });
}


function user_has_read_all_infobits(User $user, Page $topic) {
  return $topic
    ->children()
    //->filter(function ($page) { return 'infobit' === $page->template(); })
    ->every(function ($page) use ($user) {
      return Pagelist\has($user, INFOBITS_FIELD, $page);
    });
}

function ifpred($x, $predicate, $default) {
  if (call_user_func($predicate, $x)) {
    return $x;
  }
  else {
    return $default;
  }
}

/**
 * Mark the given page as read by the user.
 */
function user_read_page(User $user, Page $page) {
  Pagelist\add($user, INFOBITS_FIELD, $page);
}

/**
 * @return bool
 */
function page_assigned_to_user(User $user, Page $page) {
  return Pagelist\has($user, TOPICS_FIELD, $page);
}

/**
 * 
 * @return bool
 */
function infobit_assigned_to_user(User $user, Page $page) {
  return Pagelist\has($user, TOPICS_FIELD, $page->parent());
}

/**
 * Adds the given page to the user's reading assignments.
 * @param User $user 
 * @param Page $page The page the user should read
 */
function assign_page_to_user(User $user, Page $page) {
  Pagelist\add($user, TOPICS_FIELD, $page);
}

/**
 * Takes a User and returns the Pages the user is expected to read.
 * @param User $user
 * @return Array of Page objects
 */
function due_assignments(User $user) {
  // missing
}


function unassign_page(User $user, Page $page) {
  Pagelist\remove($user, TOPICS_FIELD, $page);
}


/**
 * @param Page $page
 * @return Page or false
 */
function part_of_assignment(Page $page) {
  if (!is_null($page->parent()) && $page->parent()->has('uuid')) {
    return $page->parent();
  }
}


/**
 * @param \User $user
 * @param \Page $topic
 * @return float 
 */
function topic_completion(\User $user, \Page $topic) {
  
}


/**
 * @return bool
 */
function user_has_read_page(User $user, Page $page) {
  $pagesRead = ifpred($user->pages_read, 'is_array', []);
  $hasRead = in_array(intval($page->uuid()->value), $pagesRead);
  return $hasRead;
}
