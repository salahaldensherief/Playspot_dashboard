import assert from 'node:assert/strict';
import {test} from 'node:test';
import {isAnnouncementCallerAuthorized} from './authorization.js';

const request = headers => new Request('https://example.invalid/announcement', {headers});
const dependencies = overrides => ({
  authenticate: async () => null,
  authorize: async () => false,
  expectedKey: async () => 'fixture-server-secret',
  ...overrides,
});
test('anonymous and public anon-key callers are rejected', async () => {
  for (const headers of [{}, {apikey: 'fixture-public-anon-key'}]) {
    assert.equal(await isAnnouncementCallerAuthorized(request(headers), dependencies()), false);
  }
});
for (const role of ['owner', 'admin', 'cashier', 'user', 'inactive_super_admin', 'banned_super_admin']) {
  test(`${role} cannot broadcast when canonical authority denies access`, async () => {
    assert.equal(await isAnnouncementCallerAuthorized(request({Authorization: 'Bearer fixture-token'}), dependencies({
      authenticate: async () => ({id: 'fixture-user', role}),
      authorize: async () => false,
    })), false);
  });
}
test('verified active platform admin uses the caller authorization', async () => {
  const authorization = 'Bearer fixture-token';
  assert.equal(await isAnnouncementCallerAuthorized(request({Authorization: authorization}), dependencies({
    authenticate: async value => {assert.equal(value, authorization); return {id: 'fixture-admin'};},
    authorize: async value => {assert.equal(value, authorization); return true;},
  })), true);
});
test('invalid bearer token cannot reach platform authorization', async () => {
  assert.equal(await isAnnouncementCallerAuthorized(request({Authorization: 'Bearer invalid'}), dependencies({
    authorize: async () => {assert.fail('Unauthenticated caller must not authorize');},
  })), false);
});
test('trusted database key remains accepted and empty key is rejected', async () => {
  assert.equal(await isAnnouncementCallerAuthorized(request({apikey: 'fixture-server-secret'}), dependencies()), true);
  assert.equal(await isAnnouncementCallerAuthorized(request({apikey: 'anything'}), dependencies({expectedKey: async () => ''})), false);
});
