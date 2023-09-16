export function getThreadsInfo() {
  return fetch(`http://localhost:3000/api/v1/threads`)
    .then(data => data.json())
}

export function getThreadInfo(id) {
  return fetch(`http://localhost:3000/api/v1/thread/${id}`)
    .then(data => data.json())
}

export function getThreadMessages(id) {
  return fetch(`http://localhost:3000/api/v1/thread/${id}/messages`)
    .then(data => data.json())
}

export function getThreadCredentials(id) {
  return fetch(`http://localhost:3000/api/v1/thread/${id}/credentials`)
    .then(data => data.json())
}
