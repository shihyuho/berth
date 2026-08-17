#!/usr/bin/env node
/**
 * Reports commits that release-please's parser would drop whole.
 *
 * Input on stdin: `git log --format='%H%x1e%B%x1f' <range>`
 */

const {parser} = require('@conventional-commits/parser');

const RS = '\x1e';
const GS = '\x1f';

function parses(message) {
  try {
    parser(message);
    return true;
  } catch (err) {
    return err;
  }
}

function overrideFrom(body) {
  const afterBegin = (body || '').split('BEGIN_COMMIT_OVERRIDE')[1];
  if (!afterBegin) return '';
  return afterBegin.split('END_COMMIT_OVERRIDE')[0].trim();
}

async function prOverride(sha) {
  const token = process.env.GITHUB_TOKEN;
  const repo = process.env.GITHUB_REPOSITORY;
  if (!token || !repo) return '';
  const api = process.env.GITHUB_API_URL || 'https://api.github.com';
  try {
    const res = await fetch(`${api}/repos/${repo}/commits/${sha}/pulls`, {
      headers: {
        authorization: `Bearer ${token}`,
        accept: 'application/vnd.github+json',
      },
    });
    if (!res.ok) return '';
    for (const pr of await res.json()) {
      const override = overrideFrom(pr.body);
      if (override) return override;
    }
  } catch (_err) {
    // A missed rescue is a visible false alarm; a missed parser drop is silent.
  }
  return '';
}

function records(buffer) {
  const out = [];
  for (const record of buffer.split(GS)) {
    const split = record.indexOf(RS);
    if (split < 0) continue;
    const sha = record.slice(0, split).trim();
    if (!sha) continue;
    out.push({sha, message: record.slice(split + 1).replace(/^\n/, '')});
  }
  return out;
}

async function main(buffer) {
  const all = records(buffer);
  const dropped = [];
  let ignored = 0;

  for (const {sha, message} of all) {
    const failure = parses(message);
    if (failure === true) continue;
    if (parses(message.split('\n')[0] + '\n') !== true) {
      ignored++;
      continue;
    }
    const override = await prOverride(sha);
    if (override && parses(override) === true) continue;
    dropped.push({sha, message, failure});
  }

  for (const {sha, message, failure} of dropped) {
    console.error(`${sha}  ${message.split('\n')[0]}`);
    console.error(`  ${String(failure.message).split('\n')[0]}`);
  }
  console.error(
    `scanned ${all.length} | non-conventional header (ignored by design): ${ignored} | ` +
      `release-please would drop: ${dropped.length}`
  );
  if (dropped.length) {
    console.error(
      '\nEach commit above is discarded whole: its change reaches neither the changelog ' +
        'nor the version bump. Recovery is in release-workflow pitfalls Trap 19.'
    );
    process.exit(1);
  }
}

let buffer = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => (buffer += chunk));
process.stdin.on('end', () => {
  main(buffer).catch(err => {
    console.error(String(err));
    process.exit(2);
  });
});
