<?php 

return array(
  'title' => 'Users with incomplete assignments',
  'options' => array(
  ),
  'html' => function() {
    $html = '<div class="overview-widget"></div>
             <script>PageList.widget();</script>';

    return $html;
  }  
);