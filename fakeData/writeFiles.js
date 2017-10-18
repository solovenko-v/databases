import fs from 'fs'
import json2csv from 'json2csv'

const callback = fileName => err => {
  if (err) throw err
  console.log(`The file ${fileName} has been saved!`)
}

const dir = './postgres/admin/fill/'

export default data =>
  Object.keys(data).forEach(key =>
    fs.writeFile(
      `${dir}${key}.csv`,
      json2csv({ data: data[key][key], fields: data[key].fields }),
      callback(`${key}.csv`)
    )
  )
