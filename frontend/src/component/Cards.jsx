
import { useRef, useState, useEffect } from 'react'
import { fetchData } from '../global'
import ModalCreateCard from './ModalCreateCard'
import ModelEditCard from './ModelEditCard'

export default function Cards() {

    const [cards, setCards] = useState()

    // viết hàm fetch data. 
    async function getCards() {
        const subUrl = '/cards'
        try {
            const response = await fetchData(subUrl, 'GET')
            setCards(response.data)
        }
        catch (error) {
            console.log(error.message)
        }
    }
    const [decks, setDecks] = useState()
    const refModalCreateCard = useRef()
    const refModelEditCard = useRef()
    const [searchContent, setSearchContent] = useState('')


    async function getDecks() {
        try {
            const subUrl = '/decks'
            const response = await fetchData(subUrl, 'GET')
            setDecks(response.data)
        }
        catch (error) { console.log(error.message) }
    }

    function handleEditCard(event, idCard) {
        refModelEditCard.current.show(idCard)
    }


    async function handleShowModalCreateCard() {
        refModalCreateCard.current.show()
    }



    

    function handleCheckAll(event) {
        const checkboxCards = document.querySelectorAll('input[name="checkbox-card"]')
        const target = event.target
        checkboxCards.forEach(checkboxCard => {
            checkboxCard.checked = target.checked
        })
    }

    async function handleDeleteCards(event) {
        const checkboxCards = document.querySelectorAll('input[name="checkbox-card"]') // trả về nodeList 
        const checkedCheckboxes = Array.from(checkboxCards).filter(checkbox => checkbox.checked);
        const idCards = checkedCheckboxes.map(checkedCheckbox => checkedCheckbox.value)
        if (idCards.length == 0) {
            refFail.current.show('Bạn chưa chọn thẻ nào!', 2000)
            return
        }
        const queryString = idCards.map(id => `ids=${encodeURIComponent(id)}`).join('&')
        const subUrl = `/cards?${queryString}`
        try {
            await fetchData(subUrl, 'DELETE')
            await getCards()
            alert('Xóa thẻ thành công')
        }
        catch (error) {
            alert('Xóa thẻ thất bại')
        }
    }


    useEffect(() => {
        getDecks()
        getCards()
    }, [])

    useEffect(() => {
        async function search() {
            const subUrl = `/cards/search?content=${searchContent}`
            try {
                const response = await fetchData(subUrl, 'GET')
                setCards(response.data)
            }
            catch (error) { console.log(error.message) }
        }
        search()
    }, [searchContent])


    
    return <div>
        <ModalCreateCard decks={decks} getCards={getCards} ref={refModalCreateCard} />
        <ModelEditCard decks={decks} getCards={getCards} ref={refModelEditCard} />
        <div className='flex justify-end mt-10'>


            <div className='flex items-center gap-x-8'>
       
            <div className='flex items-center gap-x-8'>
                    <button onClick={handleDeleteCards}>
                        <img src="delete.png" className='w-9' alt="" />
                    </button>
                    <button onClick={handleShowModalCreateCard} className=''>
                        <img src="plus.png" className='w-9' alt="" />
                    </button>

                </div>
                <div className="max-w-md mx-auto">
                    <div className="relative">
                        <div className="absolute inset-y-0 start-0 flex items-center ps-3 pointer-events-none">
                            <svg className="w-4 h-4 text-gray-500" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 20 20">
                                <path stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="m19 19-4-4m0-7A7 7 0 1 1 1 8a7 7 0 0 1 14 0Z" />
                            </svg>
                        </div>
                        <input onChange={(event) => {
                            setSearchContent(event.target.value)
                        }} type="search" id="decks-search" className="block w-full  px-4 h-10 ps-10 text-sm text-gray-900 border border-gray-300 rounded-md bg-gray-50 focus:ring-blue-500 focus:border-blue-500" placeholder="Thuật ngữ, Định nghĩa ..." />
                    </div>
                </div>
            </div>


        </div>

        <hr className='my-8'></hr>

        {cards &&
            <div className=''>
                <div className="relative overflow-x-auto sm:rounded-md">
                    <div className='flex justify-end gap-x-10 text-sm'>
             
                    </div>
                    {cards.length != 0 ?
                        (<table className="w-full text-sm text-left rtl:text-right text-gray-500">
                            <thead className="text-sm text-gray-700 uppercase">
                                <tr>
                                    <th scope="col" className="px-6 py-5 font-medium  text-gray-900 whitespace-nowrap">
                                        <input onChange={handleCheckAll} type='checkbox' />
                                    </th>
                                    <th scope="col" className="px-6 py-5">
                                        Thuật ngữ
                                    </th>
                                    <th scope="col" className="px-6 py-5">
                                        Định nghĩa
                                    </th>
                                    <th scope="col" className="px-6 py-5">
                                        Bộ thẻ
                                    </th>
                                 
                                    <th className='text-center'>Hiệu chỉnh</th>
                                </tr>
                            </thead>
                            <tbody>
                                {cards.map(card => (
                                    <tr key={card.id} className="odd:bg-gray-100 even:bg-white">
                                        <th scope="row" className="px-6 py-5 font-medium text-gray-900 whitespace-nowrap">
                                            <input name='checkbox-card' value={card.id} type="checkbox" />
                                        </th>
                                        <td className="px-6 py-5 font-medium">
                                            {card.term}
                                        </td>
                                        <td className="px-6 py-5">
                                            {card.definition}
                                        </td>
                                        <td className="px-6 py-5">
                                            {card.deck.name}
                                        </td>
                                        
                                        <td className="px-6 py-5 text-center">
                                            <button
                                                onClick={event => {
                                                    handleEditCard(event, card.id)
                                                }}
                                                type='button'
                                            >
                                                <i className="fa-regular fa-pen-to-square text-xl"></i>
                                            </button>

                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>)
                        : (<div>
                            <span className='text-sm'>Bạn chưa tạo thẻ nào</span>
                        </div>)
                    }
                </div>
            </div>
        }
    </div>
}