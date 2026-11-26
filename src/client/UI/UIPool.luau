--!strict
-- Pool genérico: reutiliza objetos (etiquetas, partes) en vez de crearlos y destruirlos.
-- Clave para móviles: menos basura = menos tirones.

export type Pool<T> = {
	acquire: () -> T,
	release: (item: T) -> (),
	created: () -> number,
}

local UIPool = {}

function UIPool.new<T>(factory: () -> T, reset: (T) -> (), prewarm: number?): Pool<T>
	local free: { T } = {}
	local created = 0
	for _ = 1, prewarm or 0 do
		table.insert(free, factory())
		created += 1
	end
	return {
		acquire = function(): T
			local item = table.remove(free)
			if item == nil then
				created += 1
				return factory()
			end
			return item
		end,
		release = function(item: T)
			reset(item)
			table.insert(free, item)
		end,
		created = function(): number
			return created
		end,
	}
end

return UIPool
