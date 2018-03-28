<?php

function cleanup_topics() {
  
  $topics = get_topics();

  foreach ($topics as $topic) {

    if (true || !$topic->uuid()->value ||
        !$topic->has('uuid') ||
        $topic->uuid()->value == '') {

      error_log('setting uuid for ' . $topic->id());

      $topic->update([
        'uuid' => generate_page_uuid($topic)
      ]);
    }
  }
}

function cleanup_infobits() {

  foreach (get_all_infobits() as $infobit) {

    if (true || !$infobit->uuid()->value ||
        !$infobit->has('uuid') ||
        $infobit->uuid()->value == '') {

      $infobit->update([
        'uuid' => generate_page_uuid($infobit)
      ]);

    }

  }

}

function get_all_infobits() {
  return kirby()
    ->site()
    ->index()
    ->filterBy('template', 'infobit');
}



function get_topics() {
  $topics = kirby()
          ->site()
          ->index()
          ->filterBy('template', 'topic');

  $ts = [];


  foreach ($topics as $topic) {

    if ($topic->has('assignable')
        && $topic->has('uuid')) {

      $ts[] = $topic;
    }

  }

  return $ts;
}

/**
 * Generates a uuid.
 * @return string
 */
function generate_page_uuid(\Page $page) {
  $username = kirby()->site()->user()->username();

  $str = strval(time()) . $username . strval(rand()) . $page->id();

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

/**
 * Mark the given page as read by the user.
 * @param User $user
 * @param Page $user
 */
function user_read_page(User $user, Page $page) {
  Pagelist\add($user, INFOBITS_FIELD, $page);
}

/**
 * @param User $user
 * @param Page $topic
 * @return bool
 */
function page_assigned_to_user(User $user, Page $topic) {
  return Pagelist\has($user, TOPICS_FIELD, $topic);
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
 * Returns a boolean indicating if the given user read the given infobit
 * @param User $user
 * @param Page $infobit
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

/**
 * Returns an array of infobits the user has been asked to read
 * and has not yet read.
 * @param User $user
 * @return Array
 */
function get_unread_infobits(User $user) {
  $result = [];

   foreach (kirby()->site()->index()->data as $topic) {

     if ($topic->template() !== 'topic') continue;

     if (!Pagelist\has($user, TOPICS_FIELD, $topic)) continue;

     
     error_log($topic->title()->value);

     foreach ($topic->children() as $infobit) {
       $hasRead = Pagelist\has($user, INFOBITS_FIELD, $infobit);

       if (!$hasRead) {
         $result[] = $infobit;
       }
     }
   }
   
   return $result;
}

/**
 * Returns the number of unread infobits that have been assigned
 * to the given user.
 * @param User $user
 * @return int
 */
function count_unread_infobits(User $user) {
  return count(get_unread_infobits($user));
}