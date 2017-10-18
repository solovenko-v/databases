import { getPerson, getAccount, getPost, getLike } from './faker'
import writeFiles from './writeFiles'
import gaussian from 'gaussian'

const getRandomInt = max => Math.floor(Math.random() * max) + 1

const N_persons = 100 // число пользователей
const N_posts = 2000 // число постов
const minDate = Date(2014, 0, 0, 0, 0, 0, 0) // начало работы форума
const M = 5 // матожидание распределения популярности постов и активности пользователей
const dis = gaussian(5, 1.22) // 1.22^2 = 1.5 => 97% всех образцов будут лежать в диапазоне (0.5, 9.5)

const persons = [...Array(N_persons)].map((el, i) => getPerson(i + 1, dis))
const accounts = persons.map((el, i) => getAccount(el))
const posts = [...Array(N_posts)].map((el, i) =>
  getPost(i + 1, getRandomInt(N_persons), minDate, dis)
)
const likes = posts.reduce((prev, post) => {
  persons.forEach(person => {
    if (person.activity * post.popularity > 25 * M * M * Math.random()) {
      prev.push(
        getLike(person.id, post.id, post.quality > 2 * M * Math.random())
      )
    }
  })
  return prev
}, [])

console.log(likes.length)

writeFiles({
  persons: { persons, fields: ['id', 'name', 'about'] },
  accounts: {
    accounts,
    fields: ['id', 'person_id', 'login', 'email', 'password_hash', 'role']
  },
  posts: {
    posts,
    fields: ['id', 'person_id', 'title', 'body', 'created_at', 'edited_at']
  },
  likes: { likes, fields: ['post_id', 'person_id', 'status'] }
})
