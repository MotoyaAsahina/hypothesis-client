import * as sharingUtil from '../annotation-sharing';

describe('sidebar/helpers/annotation-sharing', () => {
  let fakeServiceConfig;
  let fakeServiceSettings;

  beforeEach(() => {
    fakeServiceSettings = {};
    fakeServiceConfig = sinon.stub().returns(fakeServiceSettings);

    sharingUtil.$imports.$mock({
      '../config/service-config': { serviceConfig: fakeServiceConfig },
    });
  });

  afterEach(() => {
    sharingUtil.$imports.$restore();
  });

  describe('pageSharingLink', () => {
    [
      {
        documentURI: 'https://www.example.com',
        expected: 'https://www.example.com#annotations:group:testprivate',
      },
      {
        documentURI: 'https://www.example.com/page.html?q=1',
        expected:
          'https://www.example.com/page.html?q=1#annotations:group:testprivate',
      },
      // An existing fragment is replaced.
      {
        documentURI: 'https://www.example.com/page.html#section',
        expected:
          'https://www.example.com/page.html#annotations:group:testprivate',
      },
    ].forEach(({ documentURI, expected }) => {
      it('links to the document with a group fragment', () => {
        assert.equal(
          sharingUtil.pageSharingLink(documentURI, 'testprivate'),
          expected,
        );
      });
    });

    it('does not link to a bouncer', () => {
      assert.notInclude(
        sharingUtil.pageSharingLink('https://www.example.com', 'testprivate'),
        'hyp.is',
      );
    });

    it('returns null if the `documentURI` is not a shareable URI', () => {
      assert.isNull(
        sharingUtil.pageSharingLink('file://on-my-computer.pdf', 'testprivate'),
      );
    });
  });

  describe('isShareableURI', () => {
    [
      'http://www.example.com',
      'http://www.foo.bar',
      'http://hi',
      'http:foo',
      'https://www.foo.bar/baz/ding.html',
      'HTTP://WWW.FOO.BAR/BAZ',
      'HTTPS://WWW.FOO.COM',
    ].forEach(validURI => {
      it('returns true for URLs with http and https protocols', () => {
        assert.isTrue(sharingUtil.isShareableURI(validURI));
      });
    });

    [
      'httf://www.example.com',
      'htt://whatever',
      'ftp://warez.napster.nostalgia',
      'file://hithere',
      'chrome://extensions',
      'http//www.wrong',
      'www.example.com',
    ].forEach(invalidURI => {
      it('returns false for any URL not beginning with http or https', () => {
        assert.isFalse(sharingUtil.isShareableURI(invalidURI));
      });
    });
  });

  describe('sharingEnabled', () => {
    it('returns true if no service settings present', () => {
      fakeServiceConfig.returns(null);
      assert.isTrue(sharingUtil.sharingEnabled({}));
    });

    it('returns true if service settings do not have a `enableShareLinks` prop', () => {
      // service config is an empty object
      assert.isTrue(sharingUtil.sharingEnabled({}));
    });

    it('returns true if service settings `enableShareLinks` is non-boolean', () => {
      fakeServiceConfig.returns({ enableShareLinks: 'foo' });
      assert.isTrue(sharingUtil.sharingEnabled({}));
    });

    it('returns false if service settings really sets it to `false`', () => {
      fakeServiceConfig.returns({ enableShareLinks: false });
      assert.isFalse(sharingUtil.sharingEnabled({}));
    });
  });
});
