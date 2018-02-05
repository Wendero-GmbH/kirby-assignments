<div id="my-assignments" class="ui modal">
  <div class="header">Your Assignments</div>
  <div class="content">

    <div class="ui relaxed divided list">
      <?php foreach (topics_assigned_to_user(kirby()->site()->user()) as $topic): ?>

      <?php foreach (get_infobits($topic) as $infobit): ?>

      <?php if (!has_read_infobit(kirby()->site()->user(), $infobit)): ?>


      <div class="item">
        <i class="large github middle aligned icon"></i>
        <div class="content">
          <span class="header">
            <a href="<?php echo $topic->url() ?>">
              <?php echo $topic->title()->value ?>
            </a>
            <span style="color: rgba(0,0,0,.7);">/</span>
            <a href="<?php echo $infobit->url() ?>">
              <?php echo $infobit->title()->value ?>
            </a>
          </span>
          <div class="description">
            <?php echo infobit_gist($infobit); ?>
          </div>
        </div>
      </div>


      <?php endif; ?>

      <?php endforeach; ?>

      <?php endforeach; ?>

    </div>
  </div>
</div>
