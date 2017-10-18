import faker from 'faker'

faker.locale = 'en'

const getRandomInt = (min, max) =>
  min + Math.floor(Math.random() * (max - min)) + 1

const postBody = (dis, textPreview) =>
  [...Array(Math.floor(dis.ppf(Math.random())))].reduce(
    (prev, current) => prev + '\n' + faker.lorem.paragraphs(),
    textPreview
  )

export const getPerson = (id, dis) => ({
  id,
  name: faker.name.findName(),
  about: faker.name.jobType(),
  activity: dis.ppf(Math.random())
})

export const getAccount = person => ({
  id: person.id,
  person_id: person.id,
  login: faker.internet.userName(getRandomInt(5, 15)),
  email: faker.internet.email(),
  password_hash: faker.internet.password(getRandomInt(5, 10)), // need to encrypt in the postgress
  role: 'user'
})

export const getPost = (id, person_id, minDate, dis) => {
  const textPreview = faker.lorem.paragraphs()
  const created_at = faker.date.between(minDate, Date())
  return {
    id,
    person_id,
    title: faker.lorem.sentence(),
    body: postBody(dis, textPreview),
    created_at,
    edited_at: faker.date.between(created_at, Date()),
    popularity: dis.ppf(Math.random()),
    quality: dis.ppf(Math.random())
  }
}

export const getLike = (person_id, post_id, status) => ({
  person_id,
  post_id,
  status
})
