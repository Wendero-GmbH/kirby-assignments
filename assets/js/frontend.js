(function () {
  
  function initPanel(el) {
    let hasReadRaw = el.getAttribute('data-has-read');

    if (hasReadRaw !== 'true' && hasReadRaw !== 'false') {
      throw new Error('data-has-read must be "true" or "false"');
    }

    let hasRead = 'true' === hasReadRaw;

    let isAssignedRaw = el.getAttribute('data-is-assigned');

    if (isAssignedRaw !== 'true' && isAssignedRaw !== 'false') {
      throw new Error('data-is-assigned must be "true" or "false"');
    }

    let isAssigned = 'true' === isAssignedRaw;

    let confirmationEl = el.querySelector('.infobit-panel__confirmation');

    let actionEl = el.querySelector('.infobit-panel__action');

    let buttonEl = el.querySelector('button');

    let pageUuid = el.getAttribute('data-page-uuid');

    let b = new Button(buttonEl, pageUuid);

    if (hasRead) {
      confirmationEl.style.display = 'block';
    }
    else if (!hasRead && isAssigned) {
      actionEl.style.display = 'block';
      b.cb_ = () => {
        //confirmationEl.style.display = 'block';
        //actionEl.style.display = 'none';

        $(actionEl)
          .transition('slide left', null, () =>
                      $(confirmationEl).transition('slide right'));
      };

    }
    
  }


  class Button {

    constructor(element, pageUuid) {
      this.element_ = element;
      this.pageUuid_ = pageUuid;

      this.handleClickBound_ = this.handleClick_.bind(this);
      this.element_.addEventListener('click', this.handleClickBound_);
      this.cb_ = function () {};
    }

    handleClick_(ev) {
      this.element_.classList.add('loading');
      Button
        .markAsRead_(this.pageUuid_)
        .then(() => {
          this.element_.value = 'Done';
          this.element_.classList.remove('loading');
          this.cb_();
        });
    }

    static markAsRead_(pageUuid) {
      return new Promise((resolve, reject) => {

        let r = new XMLHttpRequest();
        r.open('POST', '/jsonrpc', true);
        r.responseType = 'json';
        r.onreadystatechange = () => {
          if (r.readyState != 4 || r.status != 200) return;

          resolve(r.response['result']);
        };

        let body = {
          'jsonrpc': '2.0',
          'method': 'rpc_mark_as_completed',
          'params': [pageUuid],
          'id': 1
        };

        r.send(JSON.stringify(body));
      });
    }

  }

    window.addEventListener('load', () => {
      window.setTimeout(() => {
        let el = document.querySelector('.infobit-panel')
        
        if (el) {
          initPanel(el);
        }
      }, 1000);
    });
})();
