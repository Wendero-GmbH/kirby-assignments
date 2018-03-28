
<?php
$unreadInfobits = get_unread_infobits(kirby()->site()->user());
?>

<div id="my-assignments" class="ui modal">
  <div class="header">Your Assignments</div>
  <div class="content">

    <?php if (0 == count($unreadInfobits)): ?>

    <div class="ui icon message">
      <i class="thumbs up icon"></i>
      <div class="content">
        <div class="header">
          You currently have no assignments.
        </div>
        <p>
          When your team head assigns new assignments to you, they will show up here.
        </p>
      </div>
    </div>

    <?php else: ?>
    <div class="ui relaxed divided list">

      <?php foreach ($unreadInfobits as $infobit): ?>

      <div class="item">
        <i class="large github middle aligned icon"></i>
        <div class="content">
          <span class="header">
            <a href="<?php echo $infobit->parent()->url() ?>">
              <?php echo $infobit->parent()->title()->value ?>
            </a>
            <span style="color: rgba(0,0,0,.7);">/</span>
            <a href="<?php echo $infobit->url() ?>">
              <?php echo $infobit->title()->value ?>
            </a>
          </span>
          <div class="description">
            <!--<?php echo infobit_gist($infobit); ?>-->
          </div>
        </div>
      </div>

      <?php endforeach; ?>

    </div>
    <?php endif; ?>
  </div>
</div>
