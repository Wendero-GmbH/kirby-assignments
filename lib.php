<?php

/**
 * Generates a uuid.
 * @return string
 */
function generate_page_uuid() {
  $username = kirby()->site()->user()->username();

  $str = strval(time()) . $username;

  return md5($str);
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
function topics_assigned_to_user(User $user) {
  return Pagelist\all($user, TOPICS_FIELD);
}

function get_infobits(Page $topic) {
  return $topic->children();
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

/**
 * @return bool
 */
function has_read_infobit(User $user, Page $infobit) {
  return Pagelist\has($user, INFOBITS_FIELD, $infobit);
}

/**
 * Returns a short summary or gist for the given infobit.
 * @param Page $infobit
 * @return string
 */
function infobit_gist(Page $infobit) {
  return 'Lorem ipsum dolor sit amet';
}

/**
 * Returns a boolean indicating if the user has incomplete assignments.
 * @return bool
 */
function has_assignments(User $user) {
  foreach (topics_assigned_to_user(kirby()->site()->user()) as $topic) {

    foreach (get_infobits($topic) as $infobit) {

      if (!has_read_infobit(kirby()->site()->user(), $infobit)) {
        return true;
      }
    }
  }

  return false;
}