(function () {

  function rpc(method, params) {
    return new Promise((resolve, reject) => {
      let r = new XMLHttpRequest();
      r.open('POST', API_ENDP, true);
      r.responseType = 'json';
      r.onreadystatechange = () => {
        if (r.readyState != 4) return;

        if (r.status == 200) resolve(r.response.result);
        else reject();
      };
      let body = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': method,
        'params': params
      };
      r.send(JSON.stringify(body));
    });
    
  }

  const API_ENDP = '/jsonrpc';

  class Assigner {

    constructor(el, pageUuid) {
      this.reloadBound_ = this.reload_.bind(this);
      this.handleClickBound_ = this.handleClick_.bind(this);
      this.el_ = el;
      this.pageUuid_ = pageUuid;

      this.el_.addEventListener('click', this.handleClickBound_);
      this.reload_();
      this.el_.classList.add('assignable-field');
    }

    clear_() {
      let r = document.createRange();
      r.selectNodeContents(this.el_);
      r.deleteContents();
    }

    reload_() {
      Assigner
        .loadUsers(this.pageUuid_)
        .then((users) => {

          const f = document.createDocumentFragment();

          users.forEach((u) => {
            let el = Assigner.renderUser_(u['name'], u['status']);
            f.appendChild(el);
          });

          this.clear_();
          this.el_.appendChild(f);
        })
        .catch((e) => this.displayError_('Unable to load users'));
    }

    displayError_(msg) {
      this.clear_();
      this.el_.innerHTML = `An error occurred: ${msg}. Please make sure you are logged in.`;
    }

    handleClick_(ev) {
      if (undefined === ev.target.dataset.user) return;

      let user = ev.target.dataset.user;
      let status = ev.target.dataset.status;

      if ('unassigned' === status) {
        Assigner
          .assignUser(user, this.pageUuid_)
          .then(this.reloadBound_)
          .catch(() => this.displayError_('Unable to remove the assignment'));
      }
      else {
        Assigner
          .unassignUser(user, this.pageUuid_)
          .then(this.reloadBound_)
          .catch(() => this.displayError_('Unable to assign the topic'));
      }
    }

    static statusStr(status) {
      switch (status) {
      case 'unassigned':
        return 'The topic has not been assigned to this user';
        break;
      case 'incomplete':
        return 'The user has not completed the assigned';
        break;
      case 'done':
        return 'The user has read all infobits for this topic';
        break;
      default:
        throw new Error(`Invalid status ${status}`);
      }
    }

    static renderUser_(name, status) {
      let el = document.createElement('div');

      el.classList.add('assignable-field__user');

      if (status === 'done') {
        el.classList.add('assignable-field__user--done');
      }
      else if (status === 'incomplete') {
        el.classList.add('assignable-field__user--incomplete');
      }

      el.dataset.user = name;
      el.dataset.status = status;
      el.innerHTML = `${name}`;
      el.title = Assigner.statusStr(status);
      return el;
    }


    // wrappers for rpc methods

    static loadUsers(pageUuid) {
      return rpc('rpc_get_users', [pageUuid]);
    }

    static assignUser(username, pageUuid) {
      return rpc('rpc_assign_page_to_user', [pageUuid, username]);
    }

    static unassignUser(username, pageUuid) {
      return rpc('rpc_unassign_page', [pageUuid, username]);
    }
  }

  window.Assigner = Assigner;
})();
