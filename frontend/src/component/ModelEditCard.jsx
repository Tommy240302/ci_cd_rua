import React, { useState } from "react"
import { baseUrl, fetchData } from "../global"

const ModelEditCard = React.forwardRef(({ decks, getCards }, ref) => {

    const [isShow, setIsShow] = useState(false)
    const [card, setCard] = useState()
    const accessToken = localStorage.getItem('accessToken')

    async function getCard(idCard) {
        const subUrl = `/cards/${idCard}`
        try {
            const response = await fetchData(subUrl, 'GET')
            setCard(response.data)
        }
        catch(error) {
            console.log(error.message)
        }        
    }
    function show(idCard) {
        setIsShow(true)
        getCard(idCard)
    }

    function close() {
        setIsShow(false)
    }



    async function handleEditCard(event) {
        event.preventDefault()
        
        const url = `${baseUrl}/cards/${card.id}`
        const formData = new FormData()

        const inputTermCard = document.getElementById('card-term')
        const inputDefinitionCard = document.getElementById('card-definition')
        const inputExampleCard = document.getElementById('card-example')
        const inputImageCard = document.getElementById('card-image')
    
        const selectIdDeckCard = document.getElementById('card-id-deck')

        formData.append('idDeck', selectIdDeckCard.value)
        formData.append('term', inputTermCard.value)
        formData.append('definition', inputDefinitionCard.value)
        formData.append('example', inputExampleCard.value)

    
        if (inputImageCard.files.length > 0) {
            formData.append('image', inputImageCard.files[0])
        }

        try {
            const jsonRp = await fetch(url, {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                },
                body: formData
            })
            const {message} = await jsonRp.json()
            if (!jsonRp.ok) {
                throw new Error(message)
            }
            alert(message)
            getCards()
        }
        catch (error) {
            const {message} = error
            alert(message)
        }
    }

    React.useImperativeHandle(ref, () => ({
        show
    }));

    return (isShow && card && <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-40">
        <div className="bg-white p-6 rounded-lg shadow z-50">
            <div className="flex justify-end">
                <button onClick={close} className="pr-2">
                    <i className="fa-solid fa-xmark text-4xl text-gray-500"></i>
                </button>
            </div>
            <form onSubmit={handleEditCard} className="site-create rounded-lg p-6">
                <div className="flex items-center justify-between gap-x-8">
                    <div className="w-full border-r pr-6 border-gray-400">
                        <div className="flex-col md:flex-row flex justify-between gap-x-16 mt-4">
                            <div className="flex flex-col w-full gap-y-3">
                                <label htmlFor="card-term">Thuật ngữ</label>
                                <input defaultValue={card.term} id="card-term" className="bg-transparent h-10 px-4" type="text" />
                            </div>

                            <div className="mt-4 md:mt-0 flex flex-col w-full gap-y-3">
                                <label htmlFor="">Định nghĩa</label>
                                <input defaultValue={card.definition} id="card-definition" className="bg-transparent h-10 px-4" type="text" />
                            </div>
                        </div>
                        <div className="flex-col md:flex-row flex justify-between gap-x-16 mt-4">
                            <div className="flex flex-col w-full gap-y-3">
                                <label htmlFor="">Thông tin thêm, ví dụ</label>
                                <input defaultValue={card.example} id="card-example" className="bg-transparent h-10 px-4" type="text" />
                            </div>
                            <div className="mt-4 md:mt-0 flex flex-col w-full gap-y-3">
                                <label>Bộ thẻ</label>
                                <select id='card-id-deck' className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5">
                                    {decks.map((deck) => (
                                        <option key={deck.id} value={deck.id}>{deck.name}</option>
                                    ))}
                                </select>
                            </div>
                        </div>
                    </div>
                    <div className="site-file flex flex-col gap-y-3">
                        <span>Hình ảnh</span>
                        <input id="card-image" type="file" />
                    </div>
                </div>

                <hr className="my-6"></hr>
                <div className="flex flex-col justify-start gap-y-3">

                    {card.image ? (<div className="flex justify-start">
                        <img className="object-contain w-52" src={card.image} />
                    </div>) : (
                        <span>Không có hình ảnh</span>
                    )}

                  
                </div>
                <hr className="my-6" />
                <div className='flex justify-between items-center'>

                    <button className='bg-green-600 hover:bg-green-500 text-white font-bold h-10 w-36 justify-center border-b-4 border-green-700 hover:border-green-500 rounded flex items-center gap-x-2'>
                        <span className='text-sm'>Hiệu chỉnh</span>
            
                    </button>
                </div>
            </form>
        </div>
    </div>)
})

export default ModelEditCard
