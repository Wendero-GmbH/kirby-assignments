(function () {

  const API_ENDP = '/jsonrpc';

  class Assigner {

    constructor(el, pageUuid) {
      this.reloadBound_ = this.reload_.bind(this);
      this.handleClickBound_ = this.handleClick_.bind(this);
      this.el_ = el;
      this.pageUuid_ = pageUuid;
      this.users_ = [];

      this.el_.addEventListener('click', this.handleClickBound_);
      this.reload_();
      this.el_.classList.add('assignable-field');
    }

    reload_() {
      Assigner
        .loadUsers(this.pageUuid_)
        .then((users) => {
          this.users_ = users;
          this.renderUsers_(users)
        });
    }

    handleClick_(ev) {
      if (null === ev.target.dataset.user) return;

      let user = ev.target.dataset.user;
      let status = ev.target.dataset.status;

      if ('unassigned' === status) {
        Assigner
          .assignUser(user, this.pageUuid_)
          .then(this.reloadBound_);
      }
      else {
        Assigner
          .unassignUser(user, this.pageUuid_)
          .then(this.reloadBound_);
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

    renderUsers_(users) {
      this.el_.innerHTML = '';

      users.forEach((user) => {

        let el = Assigner.renderUser_(1, user['name'], user['status']);



        this.el_.appendChild(el);
      });
    }

    static loadUsers(pageUuid) {
      return new Promise((resolve, reject) => {
        let r = new XMLHttpRequest();
        r.open('POST', API_ENDP, true);
        r.responseType = 'json';
        r.onreadystatechange = () => {
          if (r.readyState != 4 || r.status != 200) return;

          resolve(r.response['result']);
        };

        let body = {
          'jsonrpc': '2.0',
          'method': 'rpc_get_users',
          'params': [pageUuid],
          'id': 1
        };

        r.send(JSON.stringify(body));
      });
    }

    static assignUser(username, pageUuid) {
      return new Promise((resolve, reject) => {

        let r = new XMLHttpRequest();
        r.open('POST', API_ENDP, true);
        r.responseType = 'json';
        r.onreadystatechange = () => {
          if (r.readyState != 4 || r.status != 200) return;

          resolve();
        };
        let body = {
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'rpc_assign_page_to_user',
          'params': [pageUuid, username]
        };
        r.send(JSON.stringify(body));
      });      
    }

    static unassignUser(username, pageUuid) {
      return new Promise((resolve, reject) => {
        let r = new XMLHttpRequest();
        r.open('POST', API_ENDP, true);
        r.responseType = 'json';
        r.onreadystatechange = () => {
          if (r.readyState != 4 || r.status != 200) return;
          resolve();
        };
        let body = {
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'rpc_unassign_page',
          'params': [pageUuid, username]
        };
        r.send(JSON.stringify(body));
      });
    }

    static renderUser_(id, name, status) {
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
  }

  window.Assigner = Assigner;
})();
