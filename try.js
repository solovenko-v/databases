const faker = require('faker')

faker.locale = 'en'

const dateOfPast = faker.date.past()
console.log(dateOfPast, faker.date.between(dateOfPast, Date()))